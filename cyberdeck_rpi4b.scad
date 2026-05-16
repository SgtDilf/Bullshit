// ============================================================
//  Cyberdeck Case - Raspberry Pi 4B  (concept / layout tool)
//  All dimensions in mm. Toggle options at the top.
// ============================================================

// --- OPTIONS ------------------------------------------------
SCREEN_SIZE   = 7;    // 5 or 7 (inches)
SHOW_PI       = true;
SHOW_SCREEN   = true;
SHOW_KEYBOARD = true;
SHOW_CASE     = true;
SHOW_EXPLODED = false; // spread layers apart to see internals

WALL = 3;             // wall thickness
// ------------------------------------------------------------

// ---- derived explode offset --------------------------------
EXP = SHOW_EXPLODED ? 30 : 0;

// ---- screen panel dimensions (display area + bezel) --------
// 5" typical panel  ~121 x 76 mm
// 7" typical panel  ~165 x 104 mm
SCR_W = SCREEN_SIZE == 7 ? 165 : 121;
SCR_H = SCREEN_SIZE == 7 ? 104 :  76;
SCR_D = 6;    // panel depth

// ---- Raspberry Pi 4B (actual PCB: 85 x 56 x ~17 w/ ports) -
PI_W = 85;
PI_D = 56;
PI_H = 17;

// ---- keyboard placeholder ----------------------------------
// Rough sizes for common small boards:
//   65%  ~295 x 105 mm
//   60%  ~285 x 100 mm
//   Half-pitch "deck" style ~200 x 90 mm
KB_W = 295;
KB_D = 105;
KB_H = 12;

// ---- case inner cavity -------------------------------------
// Wide enough for keyboard, tall enough to stack screen + Pi
INNER_W = max(KB_W, SCR_W) + 20;
INNER_D = SCR_D + PI_H + 30;   // screen depth + pi height + air
INNER_H = KB_D + SCR_H + 20;   // keyboard depth  + screen height + margin

CASE_W = INNER_W + WALL*2;
CASE_D = INNER_D + WALL*2;
CASE_H = INNER_H + WALL*2;

// ---- colors (for preview) ----------------------------------
module color_case()    { color([0.15, 0.15, 0.18]) children(); }
module color_pi()      { color([0.13, 0.40, 0.13]) children(); }
module color_screen()  { color([0.05, 0.05, 0.08]) children(); }
module color_display() { color([0.20, 0.50, 0.80, 0.6]) children(); }
module color_kb()      { color([0.25, 0.25, 0.28]) children(); }

// ============================================================
//  CASE SHELL
// ============================================================
module case_shell() {
    color_case()
    difference() {
        // outer box - chamfered look via minkowski
        minkowski() {
            cube([CASE_W - 4, CASE_D - 4, CASE_H - 4], center=true);
            sphere(r=2, $fn=16);
        }
        // hollow inside
        cube([INNER_W, INNER_D, INNER_H], center=true);

        // --- port cutouts on the back face (Pi side) ---
        // USB-A x2
        translate([-PI_W/2 + 10, -(CASE_D/2), -INNER_H/2 + KB_D + 10])
            cube([28, WALL*3, 15], center=true);
        // USB 3 x2
        translate([-PI_W/2 + 44, -(CASE_D/2), -INNER_H/2 + KB_D + 10])
            cube([28, WALL*3, 15], center=true);
        // HDMI micro x2
        translate([PI_W/2 - 25, -(CASE_D/2), -INNER_H/2 + KB_D + 10])
            cube([22, WALL*3, 8], center=true);
        // USB-C power
        translate([PI_W/2 + 5, -(CASE_D/2), -INNER_H/2 + KB_D + 10])
            cube([10, WALL*3, 5], center=true);
        // 3.5mm audio jack
        translate([PI_W/2 - 5, -(CASE_D/2), -INNER_H/2 + KB_D + 20])
            cylinder(h=WALL*3, r=3, center=true, $fn=16);

        // --- vent slots on top ---
        for(i=[-2:2])
            translate([i*18, CASE_D/2 - WALL/2, CASE_H/2 - 15])
                cube([8, WALL*3, 25], center=true);

        // --- screen opening on front face ---
        translate([0, CASE_D/2, INNER_H/2 - SCR_H/2 - 5])
            cube([SCR_W - 8, WALL*3, SCR_H - 8], center=true);
    }
}

// ============================================================
//  RASPBERRY PI 4B (simplified PCB + port bumps)
// ============================================================
module raspberry_pi() {
    color_pi() {
        // PCB
        cube([PI_W, PI_D, 2], center=true);
        // USB stack
        translate([-PI_W/2 + 13, -PI_D/2 + 9, 4])
            cube([26, 16, 14], center=true);
        translate([-PI_W/2 + 13, -PI_D/2 + 27, 4])
            cube([26, 16, 14], center=true);
        // Ethernet
        translate([-PI_W/2 + 13, PI_D/2 - 12, 4])
            cube([22, 18, 13], center=true);
        // USB-C power + HDMI ports (side)
        translate([PI_W/2 - 14, -PI_D/2 + 11, 2])
            cube([16, 8, 5], center=true);
        translate([PI_W/2 - 28, -PI_D/2 + 11, 2])
            cube([16, 8, 5], center=true);
        // GPIO header
        translate([PI_W/2 - 16, PI_D/2 - 5, 3])
            cube([52, 5, 7], center=true);
        // SoC
        translate([0, 0, 3])
            cube([16, 16, 5], center=true);
        // SD card slot
        translate([-PI_W/2 + 3, 0, -2])
            cube([3, 12, 3], center=true);
    }
}

// ============================================================
//  SCREEN PANEL
// ============================================================
module screen_panel() {
    // bezel frame
    color_screen()
    difference() {
        cube([SCR_W, SCR_D, SCR_H], center=true);
        cube([SCR_W - 14, SCR_D + 1, SCR_H - 14], center=true);
    }
    // active display area (semi-transparent)
    color_display()
        cube([SCR_W - 14, SCR_D - 1, SCR_H - 14], center=true);
}

// ============================================================
//  KEYBOARD PLACEHOLDER
// ============================================================
module keyboard() {
    color_kb() {
        // deck plate
        cube([KB_W, KB_D, KB_H], center=true);
        // key bumps row hints
        for(row=[-1:1])
            for(col=[-7:7])
                translate([col * 19, row * 19, KB_H/2 + 2])
                    cube([16, 16, 3], center=true);
    }
}

// ============================================================
//  ASSEMBLY
// ============================================================

// --- Case shell ---
if(SHOW_CASE) case_shell();

// --- Screen (front-top, tilted slightly for ergonomics) ---
if(SHOW_SCREEN)
    translate([0, CASE_D/2 - SCR_D/2, INNER_H/2 - SCR_H/2 - 5 + EXP])
        rotate([-5, 0, 0])
            screen_panel();

// --- Raspberry Pi (sits inside, above keyboard bay) ---
if(SHOW_PI)
    translate([0, -INNER_D/4, -INNER_H/2 + KB_D + PI_H/2 + 5 - EXP])
        rotate([0, 0, 0])
            raspberry_pi();

// --- Keyboard (bottom bay) ---
if(SHOW_KEYBOARD)
    translate([0, -INNER_D/4 + 5, -INNER_H/2 + KB_D/2 + WALL - EXP*1.5])
        keyboard();


// ============================================================
//  DIMENSION REFERENCE  (shown as thin outlines at origin)
// ============================================================
module dim_line(len, axis) {
    color("red", 0.5)
    if(axis=="x") cube([len,0.5,0.5], center=true);
    else if(axis=="y") cube([0.5,len,0.5], center=true);
    else cube([0.5,0.5,len], center=true);
}

// uncomment to see overall bounding box:
// color("yellow",0.1) cube([CASE_W, CASE_D, CASE_H], center=true);

echo(str("=== Case outer dims: ", CASE_W, " x ", CASE_D, " x ", CASE_H, " mm"));
echo(str("=== Screen size: ", SCREEN_SIZE, "\" panel  (", SCR_W, " x ", SCR_H, " mm)"));
echo(str("=== Keyboard bay: ", KB_W, " x ", KB_D, " mm"));
