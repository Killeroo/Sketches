import java.util.Iterator;

final float GRAVITY = 0.03; //0.05

// TODO:
// -------
// Must:
// -> Final polish, comments and efficientsy pass
// -> Dynamic Emission Generation
//    +> Rip out generic Emissions (DONE)
//    +> Wire up emmission triggers in Particle
//    +> Keep some full Emissions (DONE)
// -> Clean the code
//    +> Add comments and seperators (DONE)
//    +> Move constants to start
//    +> Rename particles (SparklingParticle -> SparklingParticleParticle) (DONE)
//    +> Add explanation to what each particle does (DONE)
//    +> Cleanup base particle class (DONE)
// -> Better firework scatter patterns, dynamically change firerate (DONE)

// Should:
// -> Capitalise function and public variable names 
// -> Can you clean up the ParticleSystem updaters? (DONE)
// -> Randomised particle gravity, speed and size of particle
// -> Stop initial upward force being default behaviour (DONE)
// -> Slow down floater particles over lifespan like an actual firework (DONE)

// Nice to have:
// -> New particles:
//    +> Octopus wandering (WON'T ADD)
//    +> Explosions within explosions (DONE)
// -> Make the explosion code less hacky (DONE)
// -> Add functions to generate colour relations of base colours
//    +> Convert HSL then work out colour compliments etc
//    +> Find out how the colour wheels do it
//    +> Experiment with HSL and changing lightnes over lifespan
//    (https://medium.com/@MateMarschalko/dynamic-colour-palettes-with-sass-and-hsl-805b8bbef758)

/* General simultation options */
final boolean ENABLE_EXPLOSION_FLASHES = false;
final int BACKGROUND_COLOUR = 0;
final int MOTION_BLUR_FACTOR = 20; // Lower = more motion blur

/* Initial firework properties */
final int MIN_INITIAL_SIDEWAYS_FORCE = -1;
final int MAX_INITIAL_SIDEWAYS_FORCE = 1;
final int MIN_INITIAL_UPWARDS_FORCE = -10;
final int MAX_INITIAL_UPWARDS_FORCE = -30;

/* Base particle properties */ 

// Internal variables
ParticleSystem system = new ParticleSystem();
int interval = 0;
boolean flashing = false;
boolean bursting = false;

void setup()
{
  size(1000, 1000);  
}

void draw()
{
  if (flashing && ENABLE_EXPLOSION_FLASHES) {
    background(255);
    flashing = false;
  } else {
    // Motion blur
    noStroke();
    fill(BACKGROUND_COLOUR, MOTION_BLUR_FACTOR);
    rect(0, 0, width, height);
  }
  
  // Update the particle system
  system.update();
  
  if (millis() > interval) {
    // Position the particle bottom center
    Particle p = new Particle(new PVector(width/2, height));
    
    // Apply some initial upward force
    p.applyForce(new PVector(random(MIN_INITIAL_SIDEWAYS_FORCE, MAX_INITIAL_SIDEWAYS_FORCE), random(MIN_INITIAL_UPWARDS_FORCE, MAX_INITIAL_UPWARDS_FORCE)));
    
    // Add to particle system
    system.particles.add(p);
    
    // Interval between initial fireworks
    if (bursting) {
      interval = millis() + 500;  
    } else {
      interval = millis() + 2000;  
    }
  }
}

void mousePressed()
{
  bursting = !bursting;  
}

//////////////////////////////////////////////////////////////////////////////////////
// Particle system
// Controls, displays and updates every particle in the sketch.
// (we do implement some specific behaviours for some particle types here so watch out)
//////////////////////////////////////////////////////////////////////////////////////
class ParticleSystem
{
  // Initial particles
  ArrayList<Particle> particles = new ArrayList<Particle>();
  
  // All sub particles
  ArrayList<RandomMovementParticle> RandomMovementParticles = new ArrayList<RandomMovementParticle>();
  ArrayList<FloatingParticle> FloatingParticles = new ArrayList<FloatingParticle>();
  ArrayList<FallingParticle> FallingParticles = new ArrayList<FallingParticle>();
  ArrayList<TwistingParticle> TwistingParticles = new ArrayList<TwistingParticle>();
  ArrayList<SparklingParticle> SparklingParticles = new ArrayList<SparklingParticle>();
  ArrayList<TrailingParticle> TrailingParticles = new ArrayList<TrailingParticle>();
  ArrayList<SplitterParticle> SplitterParticles = new ArrayList<SplitterParticle>();
  ArrayList<SplitterParticle> SplitterParticlesToAdd = new ArrayList<SplitterParticle>();
  
  // Explosions rings
  ArrayList<Halo> Halos = new ArrayList<Halo>();
  
  void update()
  {  
    // Update every particle in existence
    this.updateBaseParticles();
    this.updateRandomMovementParticles();
    this.updateFloatingParticles();
    this.updateFallingParticles();
    this.updateTwistingParticles();
    this.updateSparklingParticles();
    this.updateTrailingParticles();
    this.updateSplitterParticles();
    
    // Update the halo rings that form around some explosions
    this.updateHalos();
  }
  
  // Most update functions 
  void updateBaseParticles()
  {
    // We use an interator so we can modify the contents of the list as we
    // go through it
    Iterator<Particle> i = particles.iterator();
    while (i.hasNext()) {
      Particle p = i.next();
      
      // Apply gravity
      p.applyForce(new PVector(0, GRAVITY));
      
      // Move particle position
      p.move();
      
      // Remove exploded particles
      if (p.exploded) {
        i.remove();
        continue;
      }
      
      // Remove dead particles
      if (p.isDead()) {
        i.remove();  
      } else {
        p.display();
      }
    }
  }
  
  void updateRandomMovementParticles()
  {
    Iterator<RandomMovementParticle> i = RandomMovementParticles.iterator();
    while (i.hasNext()) {
      RandomMovementParticle r = i.next();
      
      r.applyForce(PVector.random2D());
      r.vel.limit(r.limit); 
      r.move();
      
      if (r.isDead()) {
        i.remove();
      } else {
        r.display();
      }
    }
  }
  
  void updateFloatingParticles()
  {
    Iterator<FloatingParticle> i = FloatingParticles.iterator();
    while (i.hasNext()) {
      FloatingParticle f = i.next();
      
      
      f.vel.limit(f.limit);
      f.move();
      
      if (f.isDead()) {
        i.remove();
      } else {
        f.display();
      }
    }
  }
  
  void updateFallingParticles()
  {
    Iterator<FallingParticle> i = FallingParticles.iterator();
    while (i.hasNext()) {
      FallingParticle f = i.next();
      
      f.applyForce(new PVector(0, GRAVITY));
      f.move();
      
      if (f.isDead()) {
        i.remove();
      } else {
        f.display();
      }
    }
  }
  
  void updateTwistingParticles()
  {
    Iterator<TwistingParticle> i = TwistingParticles.iterator();
    while (i.hasNext()) {
      TwistingParticle t = i.next();
      
      t.applyForce(new PVector(0, 0.01)); 
      t.move();
      
      if (t.isDead()) {
        i.remove();
      } else {
        t.display();
      }
    }
  }
  
  void updateSparklingParticles()
  {
    Iterator<SparklingParticle> i = SparklingParticles.iterator();
    while (i.hasNext()) {
      SparklingParticle s = i.next();
      
      if (s.lifespan < 225) {
        
        s.applyForce(new PVector(0, 0.025));
        s.vel.limit(0.5);
      }
      
      s.sparkle();
      s.move();
      
      if (s.isDead()) {
        i.remove();
      } else {
        s.display();
      }
    }
    
  }
  
  void updateTrailingParticles()
  {
    Iterator<TrailingParticle> i = TrailingParticles.iterator();
    while (i.hasNext()) {
      TrailingParticle t = i.next();
      
      t.applyForce(new PVector(0, 0.005));
      t.move();
      
      if (t.isDead()) {
        i.remove();
      } else {
        t.display();
      }
    }
  }
  
  void updateSplitterParticles()
  {
    Iterator<SplitterParticle> i = SplitterParticles.iterator();
    while (i.hasNext()) {
      SplitterParticle t = i.next();
      
      t.applyForce(new PVector(0, GRAVITY));
      t.move();
      
      if (t.isDead()) {
        i.remove();
      } else {
        t.display();
      }
      
      // Remove particles that have exploded/split as well
      if (t.exploded) {
        i.remove();  
      }
    }
    
    // Add generated particles to main particle update list
    for (int x = 0; x < SplitterParticlesToAdd.size(); x++) {
      SplitterParticles.add(SplitterParticlesToAdd.get(x));  
    }
    
    SplitterParticlesToAdd.clear();
  }
  
  void updateHalos()
  {
    Iterator<Halo> i = Halos.iterator();
    while (i.hasNext()) {
      Halo h = i.next();
      
      h.update();
      
      if (h.isDead()) {
        i.remove();
      } else {
        h.display();
      }
    }
    
    // Add generated particles to main particle update list
    for (int x = 0; x < SplitterParticlesToAdd.size(); x++) {
      SplitterParticles.add(SplitterParticlesToAdd.get(x));  
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////
// Base particle class
// All other particle classes derive from this one
//////////////////////////////////////////////////////////////////////////////////////
class Particle
{
  PVector pos;                       // Position
  PVector vel = new PVector(0, 0);   // Velocity
  PVector acc = new PVector(0, 0);   // Acceleration
  float mass = random(2, 2.5);       // Weight (This adds more variance to movement)

  float size = 2;                    // Draw size of particle
  color c;                           // Color
  int lifespan = 400;                // Particle lifespan, decremented every update, particle destroyed when 0
  
  boolean exploded = false;          // This flag stops the firework from exploding multiple times
  boolean subParticle = false;       // This flag is used by all derived particle types, it stops them from
                                     // from exploding the way the initial particle/firework does
  
  Particle(PVector p)
  {
    pos = new PVector (p.x, p.y); 
    acc = new PVector (random(-0.1, 0.1), 0);
    c = color(255, 255, 255);
  }
  
  public void move()
  {
    vel.add(acc); // Apply acceleration
    pos.add(vel); // Apply our speed vector to our position 
    acc.mult(0);
    
    // We only 'explode' (spawn a firework explosion) when the following conditions are met:
    // 1) When the particle starts falling (vel.y/upwards velocity is below 0)
    // 2) When we haven't exploded already
    // 3) When we are not a derived particle/firework type (we don't want continous explosions for other particle effects)
    if (vel.y > 0 && !exploded && !subParticle) { 
      explode();
    }
    
    // Decrease particle lifespan
    lifespan--;
  }
  
  public void applyForce(PVector force) 
  {
    PVector f = PVector.div(force, mass);
    acc.add(f);
  }
  
  public void explode()
  {
    GenerateDynamicEmission(pos);
    
    exploded = true;
    flashing = true;
  }
  
  public void display()
  {
    // We dim the colour of the particle as the lifespan decreases 
    fill(c, map(lifespan, 0, 400, 0, 255));
    ellipse(pos.x, pos.y, size, size);
  }
  
  public boolean isDead()
  {
    if (lifespan < 0) {
      return true;
    } else {
      return false;
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////
// Firework types
// These types all derive from the base particle class, each has its own set of properties
// and movement types
//
// NOTE: Alot of the actual characteristics described in the following comments like
// application of gravity etc are done in the ParticleSystem, under the corresponding 
// function for updating the particular particle type.
// For example, RandomMovementParticles are updated in ParticleSystem.updateRandomMovementParticle()
//////////////////////////////////////////////////////////////////////////////////////

// As the name suggests, these particles have force applied to them randomly meaning they have 
// seperadic acceleration and random directional movement
class RandomMovementParticle extends Particle
{
  float limit;
  float lerpIteration = 0;
  color target;
  
  public RandomMovementParticle(PVector p)
  {
    super(p);  
    
    this.limit = 2;
    this.c = color(random(150, 255), 50, random(150, 255));
    this.target = color(50, random(150, 255), random(0, 150));
    this.subParticle = true;
    this.applyForce(PVector.random2D());
    this.lifespan = 125;
    this.size = 2.5;
  }
  void display()
  {
    fill(lerpColor(c, target, lerpIteration), map(lifespan, 0, 125, 0, 255));
    ellipse(pos.x, pos.y, size, size);
    
    lerpIteration += 0.01;
  }
}

// These particles are given an initial random outward velocity and acceleration
// and are affected by gravity so fall downwards
class FallingParticle extends Particle
{
  public FallingParticle(PVector p)
  {
    super(p);
    
    // Create initial velocity in random directions upon spawning
    this.vel = PVector.random2D().limit(random(3,6));
    this.acc = PVector.random2D().limit(random(3,6));
    this.c = color(random(0, 200), random(25, 100), random(0, 255));
    this.subParticle = true;
    this.applyForce(PVector.random2D().limit(random(2,6)));
    this.lifespan = 250;
    this.size = 1;
  }
}

// Floating particle moves out from their place of origin with a constant
// velocity that doesn't change over time, they are also not affected by gravity
class FloatingParticle extends Particle
{
  float limit = 2;
  
  public FloatingParticle(PVector p)
  {
    super(p);
    
    this.c = color(random(200, 255), random(200, 255), 0);
    this.subParticle = true;
    this.acc = PVector.random2D();
    this.applyForce(PVector.random2D());
    this.lifespan = 175;
    this.size = 3;
  }
}

// Sparkling particles are normal particles, slowed and affected by gravity
// when displayed we render small points randomly around its position to give
// the sparkle effect
class SparklingParticle extends Particle
{
  int r, g, b;
  
  public SparklingParticle(PVector p, int _r, int _g, int _b)
  {
    super(p);
    
    this.lifespan = 315;
    this.subParticle = true;
    this.vel = PVector.random2D().limit(random(0.25, 0.5));
    this.acc = PVector.random2D().limit(random(0.25, 0.5));
    
    this.r = _r;
    this.g = _g;
    this.b = _b;
  }

  void sparkle()
  {
    fill(r, b, g, lifespan);
    ellipse(random(pos.x-(5), pos.x+(5)),random(pos.y-(5),pos.y+(5)), random(1,3), random(1,3));
  }
}

// Trailing particles start off like Floating particles; with no gravity and a fixed
// velocity but after a certain period gravity is applied to them till their lifespan reaches 0
class TrailingParticle extends Particle
{
  public TrailingParticle(PVector p)
  {
    super(p);
    
    this.lifespan = (int) random(275, 350);
    this.subParticle = true;
    this.applyForce(PVector.random2D().mult(random(1, 2)));//1.5));
  }
}

// Twisters act like normal particles, are affected by gravity but instead of displaying
// an ellipse at their current position, 2 points are drawn rotating around their current 
// position
class TwistingParticle extends Particle
{
  float theta;
  float rot;
 
  // spiral off (affected by gravity)
  public TwistingParticle(PVector p)
  {
    super(p);
    this.vel = PVector.random2D().limit(random(0.5, 1));
    this.acc = PVector.random2D().limit(random(0.5, 1));
    this.c = color(random(25, 255), random(75, 125), 0);
    this.rot = random(50, 150);
    
    this.subParticle = true;
    this.applyForce(PVector.random2D().limit(random(1,2)));
    this.lifespan = 250;
    this.size = 2;
  }
  
  void display()
  {
    fill(c, map(lifespan, 0, 400, 0, 255));
    
    // Rotate around our current point in the sketch
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(theta);
    theta += TWO_PI/rot;
    ellipse(5, 5, size, size);
    ellipse(-5, -5, size, size);
    popMatrix();
  }
}

// Splitter particles act like base particle (are affected by gravity and are give
// a random inital force) but after a certain period of time they explode and spawn
// other splitter particles in their place. The number of times this occurs is 
// controlled by the iteration property which gets decremented each time they exploded
class SplitterParticle extends Particle
{
  int iterations = 3;
  
  public SplitterParticle(PVector p)
  {
    super(p);
    
    this.lifespan = 150;
    this.acc = PVector.random2D();
  }
  
  public void move()
  {
    vel.add(acc); // Apply acceleration
    pos.add(vel); // Apply our speed vector to our position 
    acc.mult(0);
    
    // Explode after an arbitary lifespan
    if (lifespan < 75 && !exploded) {
      explode();
    }
    
    // Decrease particle lifespan
    lifespan--;
  }
  
  public void explode()
  {
    // if we are at 0 iterations we don't bother spawning new particles anymore
    if (iterations == 0) {
      return;
    }
    
    // Spawn 5 new splitter particles at our position
    // (lower the iterations so we know when to stop)
    for (int i = 0; i < 5; i++) {
      SplitterParticle s = new SplitterParticle(pos);
      s.iterations = this.iterations - 1;
      s.c = this.c;
      system.SplitterParticlesToAdd.add(s);
    }
    
    // Signal for removal
    exploded = true;
  }
  
  void display()
  {
    fill (c, map(lifespan, 0, 150, 0, 255));
    ellipse(pos.x, pos.y, size, size);
  }
}

//////////////////////////////////////////////////////////////////////////////////////
// Explosion Halo 
// Draws a slowly expanding halo/circle around an explosion point. Speed is slightly
// random, size is controlled by the lifespan which is fixed because I am lazy ;)
//////////////////////////////////////////////////////////////////////////////////////

class Halo
{
  color c;
  PVector pos;
  float size = 1;
  float speed;
  int lifespan = 150;
  
  Halo(PVector start, color colour)
  {
    pos = start;
    c = colour;
    speed = random(1, 4);
  }
  
  void update()
  {
    size = size + speed;
    lifespan--; 
  }
  
  void display()
  { 
    stroke(c, map(lifespan, 0, 150, 0, 255));
    noFill();
    ellipse(pos.x, pos.y, size, size);
    noStroke();
  }
 
  boolean isDead()
  {
    if (lifespan < 0) {
      return true;
    } else {
      return false;  
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////
// Emission functions
// Control the different ways the fireworks explode (What type of particles are used,
// how many are spawned and introduces some variance to their colours, speed and gravity
//////////////////////////////////////////////////////////////////////////////////////

// Emission with all particle types, uses complimentary colours
void ComplementaryEmission(PVector pos)
{
  int particles = (int) random(10, 500);
  
  // Switch to using different compbinations of complimentary colours (adobe colour wheel)
  int base_red = (int) random(0, 255);
  int base_green = (int) random(0, 255);
  int base_blue = (int) random(0, 255);
  
  for (int x = 0; x < particles; x++) {
    
    TrailingParticle tr = new TrailingParticle(pos);
    tr.c = color(amplify(base_red), amplify(base_green), amplify(base_blue));
    system.TrailingParticles.add(tr);
    
    int count = (int) random(1, 6);
    switch(count)
    {
      case 1:
        RandomMovementParticle r = new RandomMovementParticle(pos);
        //system.RandomMovementParticles.add(r);
        break;
      case 2:
        TwistingParticle t = new TwistingParticle(pos);
        t.c = color(base_red + (int) random(0, 25), base_green + (int) random(0, 25), base_blue);
        system.TwistingParticles.add(t);
        break;
      case 3:
        for (int i = 0; i < 5; i++) {
          FallingParticle f = new FallingParticle(pos);
          f.c = color(base_red, (int) random(0, 255), base_blue + (int) random(0, 15));
          system.FallingParticles.add(f);
        }
        break;
      case 4:
        FloatingParticle fl = new FloatingParticle(pos);
        fl.c = color(base_blue, base_red + (int) random(0, 25), base_green + (int) random(0, 25));
        system.FloatingParticles.add(fl);
        break;
      case 5:
        SparklingParticle s = new SparklingParticle(pos, base_red, base_green, base_blue);
        s.c = color(base_red, base_blue, base_green);
        system.SparklingParticles.add(s);
    }
  }
}

// Dynamically generates an emission pattern from all available particle types
void GenerateDynamicEmission(PVector pos)
{
  // Base colours to derive everything from
  int base_red = (int) random(0, 255);
  int base_green = (int) random(0, 255);
  int base_blue = (int) random(0, 255);
  
  // Number of lots of particles we are going to create
  int iterations = (int) random(2, 7);
  
  // For each iteration...
  for (int x = 0; x < iterations; x++) {
    int choice = (int) random(1, 8);
    int particleCount = 0;
    
    // ... pick a random type of particle to spawn
    // (Below is every type of particle, we create variance here and add colours
    // that normally derive from the base colours)
    switch(choice) {
      case 1: 
        particleCount = (int) random(50, 150);
        for (int i = 0; i < particleCount; i++) {
          RandomMovementParticle r = new RandomMovementParticle(pos);
          r.c = color(base_red + random(-20, 20), base_blue + random(-20, 20), base_green + random(-20, 20));
          r.target = color(amplify(base_red), amplify(base_green), amplify(base_blue));
          system.RandomMovementParticles.add(r);
        }
        break;
      case 2:
        particleCount = (int) random(25, 175);
        for (int i = 0; i < particleCount; i++) {
          FloatingParticle fl = new FloatingParticle(pos);
          fl.limit = random(0.5, 2);
          fl.c = color(base_blue, base_red + (int) random(-25, 25), base_green + (int) random(-25, 25));
          system.FloatingParticles.add(fl);
        }
        break;
      case 3:
        particleCount = (int) random(50, 150);
        for (int i = 0; i < particleCount; i++) {
          FallingParticle f = new FallingParticle(pos);
          f.c = color(base_red, (int) random(0, 255), base_blue + (int) random(0, 15));
          system.FallingParticles.add(f);
        }
        break;
      case 4:
        particleCount = (int) random(10, 100);
        for (int i = 0; i < particleCount; i++) {
          TwistingParticle t = new TwistingParticle(pos);
          t.c = color(base_red + (int) random(-50, 50), base_green + (int) random(-50, 50), base_blue);
          system.TwistingParticles.add(t);
        }
        break;
      case 5:
        particleCount = (int) random(50, 150);
        for (int i = 0; i < particleCount; i++) {
          SparklingParticle s = new SparklingParticle(pos, base_red, base_green, base_blue);
          s.c = color(amplify(base_red), amplify(base_blue), amplify(base_green));
          system.SparklingParticles.add(s);
        }
        break;
      case 6:
        particleCount = (int) random(50, 150);
        for (int i = 0; i < particleCount; i++) {
          TrailingParticle t = new TrailingParticle(pos);
          t.c = color(base_red + (int) random(-30, 30), base_blue + (int) random(-30, 30), base_green + (int) random(-30, 30));
          system.TrailingParticles.add(t);
        }
        break;
      case 7:
        particleCount = (int) random(3, 5);
        for (int i = 0; i < particleCount; i++) {
          SplitterParticle p = new SplitterParticle(pos);
          p.c = color(random(0, 255), random(0, 255), random(0, 255));
          p.iterations = (int) random(1, 3);
          system.SplitterParticles.add(p);
        }
        break;
    }
  }
  
  // Only add halo rings on particularly big emissions
  if (iterations > 5) {
    Halo h = new Halo(pos, color(amplify(base_red), amplify(base_green), amplify(base_blue)));
    system.Halos.add(h);
  }
}

//////////////////////////////////////////////////////////////////////////////////////
// Helper functions
//////////////////////////////////////////////////////////////////////////////////////

// 'Brighten' a given RGB value
float amplify(float n) {
  return constrain(2 * n, 0, 255);
}
