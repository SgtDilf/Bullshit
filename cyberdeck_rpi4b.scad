// ============================================================
//  CYBERDECK  —  Raspberry Pi 4B  |  Retro Cyberpunk
//  Bambu Labs P1S  (256 x 256 x 256 mm build volume)
//  Print as two halves: split at MID_Z (horizontal cut)
// ============================================================
//
//  QUICK TOGGLES
//  -------------
SHOW_TOP_SHELL   = true;
SHOW_BTM_SHELL   = true;
SHOW_SCREEN_ASSY = true;
SHOW_PI          = true;
SHOW_KEYBOARD    = true;
SHOW_EXPLODED    = false;   // spread everything apart to inspect
HALF_SECTION     = false;   // slice in half to see interior

$fn = 60;

// ============================================================
//  CORE DIMENSIONS
// ============================================================
WALL  = 3.5;       // shell wall thickness
RAD   = 6;         // outer corner radius

// Body — wedge profile (thick at back, thin at front)
BODY_W     = 220;  // left-right
BODY_D     = 195;  // front-to-back
FRONT_H    =  32;  // body height at front edge
BACK_H     =  70;  // body height at back edge
MID_Z      =  28;  // Z height of shell split seam

// Screen assembly
SCR_W      = 132;  // 5" LCD panel width  (display + bezel)
SCR_H      =  88;  // 5" LCD panel height
SCR_D      =   7;  // panel depth
SCR_TILT   =  68;  // angle from horizontal (degrees)
SCR_THICK  =   4;  // bezel frame thickness

// Keyboard bay (recess in top face)
KB_W       = 190;
KB_D       =  88;
KB_H       =  10;
KB_OFFSET  =  20;  // from front edge of top face

// Pi 4B (real PCB dims)
PI_W = 85;  PI_D = 56;  PI_H = 17;

// Greeble / detail knobs
BOLT_R     = 2.8;  // decorative hex-bolt radius
PANEL_INSET = 1.2; // depth of recessed tech panels
RIB_W      =  4;   // structural rib width

// Explode spacing
EXP = SHOW_EXPLODED ? 35 : 0;


// ============================================================
//  HELPERS
// ============================================================

// Rounded cube (box with radius on all Z edges)
module rcube(w, d, h, r=RAD) {
    hull() {
        for(sx=[-1,1]) for(sy=[-1,1])
            translate([sx*(w/2-r), sy*(d/2-r), 0])
                cylinder(r=r, h=h);
    }
}

// Inset panel cutout (decorative recessed rectangle)
module panel_cut(w, h, depth=PANEL_INSET, r=1.5) {
    hull() {
        for(sx=[-1,1]) for(sy=[-1,1])
            translate([sx*(w/2-r), sy*(h/2-r), -depth])
                cylinder(r=r, h=depth+0.1);
    }
}

// Hex bolt boss (decorative)
module bolt_boss(h=3) {
    cylinder(r=BOLT_R, h=h, $fn=6);
    translate([0,0,h]) cylinder(r=BOLT_R*0.55, h=1.2, $fn=6);
}

// Diagonal vent slot array
module vent_array(w, h, slot_w=1.8, pitch=5, angle=45) {
    intersection() {
        cube([w, h, 20], center=true);
        for(i=[-20:20])
            rotate([0, 0, angle])
                translate([i*pitch, 0, 0])
                    cube([slot_w, w+h, 20], center=true);
    }
}

// Hex grid cutout (for decorative vents)
module hex_grid(cols, rows, cell=7, wall=1.4, depth=10) {
    s = cell + wall;
    for(r=[0:rows-1]) for(c=[0:cols-1]) {
        ox = c*s*cos(30)*2 + (r%2)*s*cos(30);
        oy = r*s*1.5;
        translate([ox, oy, 0])
            cylinder(r=cell/2, h=depth, $fn=6);
    }
}


// ============================================================
//  BODY PROFILE  (YZ cross-section, extruded along X)
//  Creates the wedge / tapered form
// ============================================================
module body_profile_2d(shrink=0) {
    s = shrink;
    pts = [
        [ s,           s          ],   // front-bottom
        [ BODY_D - s,  s          ],   // rear-bottom
        [ BODY_D - s,  BACK_H - s ],   // rear-top (square)
        [ BODY_D - 28, BACK_H + 14 - s], // rear chamfer shoulder
        [ BODY_D - 55, BACK_H + 14 - s], // screen hinge flat
        [ s + 12,      FRONT_H - s ],  // front-top
        [ s,           FRONT_H - s ]   // front chamfer
    ];
    polygon(pts);
}

module body_solid() {
    rotate([90, 0, 90])
        linear_extrude(height=BODY_W, center=true)
            offset(r=0) body_profile_2d();
}

module body_hollow() {
    rotate([90, 0, 90])
        linear_extrude(height=BODY_W - WALL*2, center=true)
            offset(r=-WALL) body_profile_2d();
}


// ============================================================
//  PORT CUTOUTS  (rear face)
// ============================================================
module port_cutouts() {
    rear_y = BODY_D/2;
    base_z = MID_Z + 4;

    // USB-A x2 (stacked)
    translate([-BODY_W/2 + 38, rear_y, base_z + 5])
        rotate([90,0,0]) cube([30, 16, WALL*3], center=true);

    // USB 3.0 x2
    translate([-BODY_W/2 + 74, rear_y, base_z + 5])
        rotate([90,0,0]) cube([30, 16, WALL*3], center=true);

    // Ethernet
    translate([-BODY_W/2 + 110, rear_y, base_z + 5])
        rotate([90,0,0]) cube([17, 15, WALL*3], center=true);

    // Micro-HDMI x2
    translate([-BODY_W/2 + 140, rear_y, base_z + 3])
        rotate([90,0,0]) cube([10, 6, WALL*3], center=true);
    translate([-BODY_W/2 + 154, rear_y, base_z + 3])
        rotate([90,0,0]) cube([10, 6, WALL*3], center=true);

    // USB-C power
    translate([-BODY_W/2 + 170, rear_y, base_z + 2])
        rotate([90,0,0]) cube([10, 5, WALL*3], center=true);

    // 3.5mm audio
    translate([-BODY_W/2 + 186, rear_y, base_z + 3])
        rotate([90,0,0]) cylinder(r=3.2, h=WALL*3, center=true);

    // MicroSD access slot (front face, low)
    translate([-BODY_W/2 + 20, -BODY_D/2, MID_Z - 5])
        rotate([90,0,0]) cube([16, 4, WALL*3], center=true);
}


// ============================================================
//  SIDE PANEL GREEBLE  (applied to each side face)
// ============================================================
module side_greeble(side=1) {
    mirror([side < 0 ? 1 : 0, 0, 0])
    translate([BODY_W/2 - 0.5, -20, 5]) {

        // Large recessed panel zone
        translate([0, 0, 22]) rotate([0,90,0])
            panel_cut(70, 34, depth=PANEL_INSET);

        // Hex vent cluster
        translate([0.4, -32, 10]) rotate([0,90,0])
            hex_grid(3, 4, cell=5.5, wall=1.2, depth=WALL+1);

        // Bolt corners of main panel
        for(bx=[-30, 30]) for(bz=[10, 36])
            translate([0.2, bx, bz]) rotate([0,90,0])
                bolt_boss(h=2.5);

        // Diagonal vent slots (lower rear)
        translate([0.4, 35, 8]) rotate([0,90,0])
            vent_array(28, 18, slot_w=1.6, pitch=4.5, angle=45);
    }
}


// ============================================================
//  TOP FACE DETAIL
// ============================================================
module top_face_detail() {
    top_z = BACK_H + 14;   // approx top face height at rear

    // Panel border around keyboard recess
    translate([0, -BODY_D/2 + KB_OFFSET + KB_D/2, top_z - 3])
        panel_cut(KB_W + 16, KB_D + 14, depth=PANEL_INSET*0.8);

    // Four corner bolts around keyboard
    for(bx=[-KB_W/2 - 6, KB_W/2 + 6]) for(by=[-KB_D/2 - 5, KB_D/2 + 5])
        translate([bx, -BODY_D/2 + KB_OFFSET + KB_D/2 + by, top_z - 0.5])
            bolt_boss(h=2.8);

    // Small recessed panels — flanking the keyboard
    for(sx=[-1, 1])
        translate([sx * (KB_W/2 + 18), -BODY_D/2 + KB_OFFSET + 25, top_z - 1])
            panel_cut(18, 40, depth=PANEL_INSET);
}


// ============================================================
//  KEYBOARD RECESS (cut into top shell)
// ============================================================
module keyboard_recess() {
    translate([0, -BODY_D/2 + KB_OFFSET + KB_D/2, BACK_H + 12])
        rcube(KB_W, KB_D, 30, r=3);
}


// ============================================================
//  SCREEN BEZEL + DISPLAY
// ============================================================
module screen_assembly() {
    // Pivot point at back-top of body
    pivot_y = BODY_D/2 - 28;
    pivot_z = BACK_H + 14;
    arm_len  = SCR_H/2 + 8;

    translate([0, pivot_y, pivot_z])
    rotate([-( 90 - SCR_TILT), 0, 0]) {

        // Bezel frame
        color([0.12, 0.12, 0.14])
        difference() {
            rcube(SCR_W + SCR_THICK*2, SCR_D + 2, SCR_H + SCR_THICK*2, r=4);
            // display window
            translate([0, -1, 0])
                cube([SCR_W - 4, SCR_D + 4, SCR_H - 4], center=true);
            // thin back face
            translate([0, SCR_D/2 + 1, 0])
                cube([SCR_W - SCR_THICK*2, 6, SCR_H - SCR_THICK*2], center=true);
        }

        // Panel details on bezel face (front)
        color([0.10, 0.10, 0.12])
        translate([0, -(SCR_D/2 + SCR_THICK/2), 0]) {
            // corner bolts
            for(bx=[-SCR_W/2+2, SCR_W/2-2]) for(bz=[-SCR_H/2+2, SCR_H/2-2])
                translate([bx, 0, bz]) rotate([90,0,0]) bolt_boss(h=2.2);
            // recessed border panel
            translate([0, 0.5, 0]) rotate([90,0,0])
                panel_cut(SCR_W - 10, SCR_H - 10, depth=0.8);
        }

        // Active display area
        color([0.05, 0.08, 0.25, 0.85])
            translate([0, -(SCR_D/2), 0])
                cube([SCR_W - 6, 1.5, SCR_H - 6], center=true);

        // Hinge knuckles
        color([0.22, 0.22, 0.25])
        for(hx=[-SCR_W/2 + 10, SCR_W/2 - 10])
            translate([hx, SCR_D/2 + 3, -SCR_H/2 - 4])
                rotate([0, 90, 0]) cylinder(r=5, h=10, center=true);
    }
}


// ============================================================
//  RASPBERRY PI 4B
// ============================================================
module raspberry_pi() {
    color([0.10, 0.36, 0.10]) {
        cube([PI_W, PI_D, 2], center=true);
        // USB-A x2
        translate([-PI_W/2+13, -PI_D/2+9,  5]) cube([26,15,12], center=true);
        translate([-PI_W/2+13, -PI_D/2+27, 5]) cube([26,15,12], center=true);
        // Ethernet
        translate([-PI_W/2+13, PI_D/2-12,  5]) cube([22,17,12], center=true);
        // HDMI x2
        translate([PI_W/2-14, -PI_D/2+11,  2]) cube([16,8,5], center=true);
        translate([PI_W/2-28, -PI_D/2+11,  2]) cube([16,8,5], center=true);
        // USB-C
        translate([PI_W/2-38, -PI_D/2+11,  2]) cube([8,5,4], center=true);
        // GPIO
        translate([PI_W/2-16, PI_D/2-5,    4]) cube([52,5,8], center=true);
        // SoC
        translate([0,4,4]) cube([16,16,6], center=true);
        // heatsink block
        color([0.55,0.55,0.55]) translate([0,4,7]) cube([18,18,4], center=true);
    }
}


// ============================================================
//  KEYBOARD PLACEHOLDER
// ============================================================
module keyboard_visual() {
    color([0.18, 0.18, 0.20]) {
        // base plate
        cube([KB_W, KB_D, 3], center=true);
        // key caps — three rows
        for(row=[0:2]) for(col=[-11:11]) {
            ky = -KB_D/2 + 15 + row*22;
            kx = col * 16;
            if(abs(kx) < KB_W/2 - 5)
                translate([kx, ky, 4])
                    rcube(13, 13, 5, r=1.5);
        }
        // space bar
        translate([0, KB_D/2 - 16, 4]) rcube(65, 13, 5, r=1.5);
    }
}


// ============================================================
//  BOTTOM SHELL
// ============================================================
module bottom_shell() {
    color([0.14, 0.14, 0.17])
    difference() {
        // outer form up to split line
        intersection() {
            body_solid();
            translate([0, 0, -1]) cube([BODY_W+10, BODY_D+10, MID_Z+1], center=true);
        }
        // hollow interior
        intersection() {
            body_hollow();
            translate([0, 0, WALL-1]) cube([BODY_W, BODY_D, MID_Z+5], center=true);
        }
        // half-section cut
        if(HALF_SECTION)
            translate([50, 0, 0]) cube([BODY_W, BODY_D+10, BACK_H+30], center=true);
    }
}


// ============================================================
//  TOP SHELL
// ============================================================
module top_shell() {
    color([0.16, 0.16, 0.19])
    difference() {
        union() {
            // body above split
            intersection() {
                body_solid();
                translate([0, 0, MID_Z]) cube([BODY_W+10, BODY_D+10, BACK_H+20], center=true);
            }
            // screen hinge block
            translate([0, BODY_D/2 - 22, BACK_H + 8])
                rcube(BODY_W - WALL*4, 28, 16, r=4);
        }

        // hollow interior (above split)
        intersection() {
            body_hollow();
            translate([0, 0, MID_Z + WALL]) cube([BODY_W, BODY_D, BACK_H+20], center=true);
        }

        // keyboard recess
        keyboard_recess();

        // top face greeble panels (cut in)
        top_face_detail();

        // port cutouts
        port_cutouts();

        // side greeble (hex vents — cut through wall)
        side_greeble( 1);
        side_greeble(-1);

        // rear top vent strip (diagonal slots)
        translate([0, BODY_D/2 - 12, BACK_H + 6])
            rotate([0, 0, 0]) vent_array(BODY_W - 30, 12, slot_w=2, pitch=6, angle=60);

        // half-section cut
        if(HALF_SECTION)
            translate([50, 0, 0]) cube([BODY_W, BODY_D+10, BACK_H+30], center=true);
    }
}


// ============================================================
//  ASSEMBLY
// ============================================================
exp_btm = SHOW_EXPLODED ? -EXP*0.4 : 0;
exp_top = SHOW_EXPLODED ?  EXP*0.6 : 0;
exp_scr = SHOW_EXPLODED ?  EXP*1.3 : 0;
exp_int = SHOW_EXPLODED ? -EXP*0.2 : 0;

if(SHOW_BTM_SHELL)
    translate([0, 0, exp_btm])
        bottom_shell();

if(SHOW_TOP_SHELL)
    translate([0, 0, exp_top])
        top_shell();

if(SHOW_SCREEN_ASSY)
    translate([0, 0, exp_scr])
        screen_assembly();

// Pi sits inside, rear of top shell
if(SHOW_PI)
    translate([-PI_W/2 + 10, BODY_D/2 - PI_D - 14, MID_Z + WALL + exp_int])
        raspberry_pi();

// Keyboard in its recess
if(SHOW_KEYBOARD)
    translate([0, -BODY_D/2 + KB_OFFSET + KB_D/2, BACK_H + 14 + exp_int])
        keyboard_visual();


// ============================================================
//  CONSOLE OUTPUT  — handy reference while tweaking
// ============================================================
echo("─────────────────────────────────────");
echo(str("Body: ", BODY_W, " × ", BODY_D, " × ", BACK_H+14, " mm"));
echo(str("Shell split at Z = ", MID_Z, " mm"));
echo(str("Screen: 5\"  (", SCR_W, " × ", SCR_H, " mm)  tilt=", SCR_TILT, "°"));
echo(str("Keyboard bay: ", KB_W, " × ", KB_D, " mm"));
echo("─────────────────────────────────────");
echo("PRINT PLAN (P1S 256³ bed):");
echo("  Part 1 — Bottom shell  (split at seam, flip upside-down)");
echo("  Part 2 — Top shell     (print right-side-up)");
echo("  Part 3 — Screen bezel  (vertical, supports on hinge)");
echo("─────────────────────────────────────");
