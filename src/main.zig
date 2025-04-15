const std = @import("std");
const rl = @import("raylib");

var playerScore: i32 = 0; // Player score
var rangerScore: i32 = 0; // Ranger (enemy) score

const SCREEN_WIDTH = 1280; // Width of the screen
const SCREEN_HEIGHT = 800; // Height of the screen
const ballRadius = 20; // Radius of the ball
const ballSpeed = 5; // Initial speed of the ball
const paddleHeight = 120; // Height of the paddles

// Ball struct definition
const Ball = struct {
    x: f32, // Ball's x-position
    y: f32, // Ball's y-position
    speedX: f32, // Ball's speed in the X direction
    speedY: f32, // Ball's speed in the Y direction
    radius: f32, // Ball's radius
    color: rl.Color, // Ball's color

    // Initialize ball with default values
    pub fn init() Ball {
        return Ball{
            .x = SCREEN_WIDTH / 2,
            .y = SCREEN_HEIGHT / 2,
            .speedX = 0,
            .speedY = 0,
            .radius = ballRadius, // Use the constant defined for ball's radius
            .color = rl.Color.lime,
        };
    }

    // Reset ball to the center of the screen
    pub fn reset(self: *Ball) void {
        self.x = SCREEN_WIDTH / 2;
        self.y = SCREEN_HEIGHT / 2;

        const randChoices: [2]i32 = .{ -1, 1 }; // Possible random direction choices
        const randomIndex: usize = @intCast(rl.getRandomValue(0, 1)); // Get a random index (0 or 1)
        self.speedX *= @floatFromInt(randChoices[randomIndex]); // Randomize ball direction horizontally
        // Optionally, uncomment below to randomize vertical speed (currently disabled)
        // self.speedY *= randChoices[rl.getRandomValue(0, 1)];
    }

    // Draw the ball on the screen
    pub fn draw(self: *Ball) void {
        rl.drawCircle(@intFromFloat(self.x), @intFromFloat(self.y), self.radius, rl.Color.lime);
    }

    // Update the ball's position and handle wall collisions
    pub fn update(self: *Ball, screen_width: f32, screen_height: f32) void {
        self.x += self.speedX; // Move ball horizontally
        self.y += self.speedY; // Move ball vertically

        // Ball hits the top or bottom walls (bounces vertically)
        if (self.y + self.radius >= screen_height or self.y - self.radius <= 0) {
            self.speedY *= -1; // Reverse the vertical direction
        }

        // Ball hits the right wall (player wins, reset the ball)
        if (self.x + self.radius >= screen_width) {
            self.speedX *= -1;
            playerScore += 1; // Increment player score
            reset(self); // Reset ball
        }
        // Ball hits the left wall (ranger wins, reset the ball)
        else if (self.x - self.radius <= 0) {
            self.speedX *= -1;
            rangerScore += 1; // Increment ranger score
            reset(self); // Reset ball
        }
    }
};

// Paddle struct definition
const Paddle = struct {
    x: f32, // Paddle's x-position
    y: f32, // Paddle's y-position
    width: f32, // Paddle's width
    height: f32 = paddleHeight, // Paddle's height (default to 120)
    color: rl.Color, // Paddle's color
    speed: f32, // Paddle's speed of movement
    name: []const u8, // Name of the player or the enemy (used for AI or player control)

    // Initialize paddle with a name
    pub fn init(name: []const u8) Paddle {
        return Paddle{
            .height = paddleHeight,
            .x = 0,
            .y = SCREEN_HEIGHT / 2 - paddleHeight / 2,
            .color = rl.Color.black, // Default paddle color is black
            .width = 25, // Default width of the paddle
            .speed = 10.0, // Default speed of the paddle
            .name = name, // Set the name (Player or Ranger)
        };
    }

    // Limit paddle movement to the screen bounds
    fn limitMovement(self: *Paddle) void {
        if (self.y <= 0) {
            self.y = 0; // Prevent paddle from going above the screen
        }
        if (self.y + self.height >= SCREEN_HEIGHT) {
            self.y = SCREEN_HEIGHT - self.height; // Prevent paddle from going below the screen
        }
    }

    // Update the paddle's position based on input or AI (for player and ranger)
    pub fn update(self: *Paddle, ball_y: f32) void {
        // PLAYER CONTROLS
        if (std.mem.eql(u8, self.name, "Player")) {
            if (rl.isKeyDown(rl.KeyboardKey.w)) {
                self.y -= self.speed; // Move the paddle up
            }

            if (rl.isKeyDown(rl.KeyboardKey.s)) {
                self.y += self.speed; // Move the paddle down
            }
        }

        // CPU CONTROLS (AI for the ranger)
        if (std.mem.eql(u8, self.name, "Ranger")) {
            if (self.y + @divTrunc(self.height, 2) > ball_y) {
                self.y -= self.speed; // Move the ranger paddle up if the ball is above
            } else if (self.y + @divTrunc(self.height, 2) < ball_y) {
                self.y += self.speed; // Move the ranger paddle down if the ball is below
            }
        }

        // LIMIT Movement
        limitMovement(self); // Ensure paddle stays within screen bounds
    }

    // Draw the paddle on the screen
    pub fn draw(self: *Paddle) void {
        rl.drawRectangleRounded(rl.Rectangle{ .x = self.x, .y = self.y, .width = self.width, .height = self.height }, 0.8, 0, self.color);
    }
};

pub fn main() !void {
    // Initialize the window and set up the screen
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Zong");
    rl.setTargetFPS(60); // Set the target FPS to 60 for smooth animation
    defer rl.closeWindow(); // Ensure the window closes when done

    // Initialize ball
    var ball = Ball.init();
    ball.radius = ballRadius; // Set the ball radius
    ball.speedX = ballSpeed; // Set the horizontal speed
    ball.speedY = ballSpeed; // Set the vertical speed

    // Initialize player paddle
    var paddlePlayer = Paddle.init("Player");
    paddlePlayer.x = 10; // Position player paddle on the left side
    paddlePlayer.color = rl.Color.white; // Set the color to white for the player

    // Initialize ranger (enemy) paddle
    var paddleEnemy = Paddle.init("Ranger");
    paddleEnemy.x = SCREEN_WIDTH - 35; // Position ranger paddle on the right side
    paddleEnemy.color = rl.Color.red; // Set the color to red for the enemy

    while (!rl.windowShouldClose()) { // Main game loop
        rl.beginDrawing(); // Begin drawing for the current frame
        defer rl.endDrawing(); // End drawing when done

        // UPDATE
        ball.update(SCREEN_WIDTH, SCREEN_HEIGHT); // Update the ball position
        paddlePlayer.update(ball.y); // Update player paddle based on ball position
        paddleEnemy.update(ball.y); // Update enemy paddle based on ball position

        // COLLISION detection
        // Check collision with player paddle
        if (rl.checkCollisionCircleRec(rl.Vector2{ .x = ball.x, .y = ball.y }, ball.radius, rl.Rectangle{ .x = paddlePlayer.x, .y = paddlePlayer.y, .width = paddlePlayer.width, .height = paddlePlayer.height })) {
            ball.speedX *= -1; // Ball bounces back on player paddle collision
        }

        // Check collision with ranger paddle
        if (rl.checkCollisionCircleRec(rl.Vector2{ .x = ball.x, .y = ball.y }, ball.radius, rl.Rectangle{ .x = paddleEnemy.x, .y = paddleEnemy.y, .width = paddleEnemy.width, .height = paddleEnemy.height })) {
            ball.speedX *= -1; // Ball bounces back on ranger paddle collision
        }

        // DRAW
        rl.clearBackground(rl.Color.black); // Clear the screen with a black background
        rl.drawCircle(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, SCREEN_WIDTH / 6, rl.Color.dark_gray); // Draw the center circle
        rl.drawLine(SCREEN_WIDTH / 2, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT, rl.Color.orange); // Draw the center dividing line

        ball.draw(); // Draw the ball
        paddlePlayer.draw(); // Draw the player paddle
        paddleEnemy.draw(); // Draw the ranger paddle

        // Display scores
        rl.drawText(rl.textFormat("Player: %d", .{playerScore}), 50, SCREEN_HEIGHT - 50, 26, rl.Color.red); // Display player score
        rl.drawText(rl.textFormat("Ranger: %d", .{rangerScore}), SCREEN_WIDTH - 150, 50, 26, rl.Color.white); // Display ranger score
    }
}
