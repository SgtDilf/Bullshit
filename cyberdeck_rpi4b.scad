// ============================================================
//  CYBERDECK — Raspberry Pi 4B
//  Dieselpunk Retrofuture  |  Integrated 40% QWERTY Clamshell
//  Bambu Labs P1S  (256 × 256 × 256 mm)
//  Print: bottom shell flat, lid flat — each fits the bed solo
// ============================================================

$fn = 50;
EPS = 0.01;

// ─── TOGGLES ────────────────────────────────────────────────
SHOW_BASE    = true;
SHOW_LID     = true;
SHOW_KEYS    = true;
SHOW_PI      = false;   // Pi 4B reference block inside
LID_OPEN     = 112;     // 0=closed  90=vertical  112=reading angle

// ─── DIMENSIONS ─────────────────────────────────────────────
CASE_W  = 218;   // left-right
CASE_D  = 118;   // front-to-hinge (each half)
BTM_H   =  44;   // base shell height
TOP_H   =  20;   // lid thickness
WALL    =   4;   // shell wall
CHAMP   =   4;   // chamfer on all body edges

// 40% keyboard — 12 cols × 4 rows, staggered
KP      =  17;   // key pitch mm
KB_W    = KP*12; // 204 mm
KB_D    = KP*4;  // 68  mm
KB_FWD  =  18;   // wrist ledge in front of keys

// 5" screen
SCR_W   = 132;
SCR_H   =  88;
SCR_D   =   7;

// Hinge barrel
HG_DIA  =  13;
HG_KNUC =   5;
HG_SPAN = 150;

// Detail
RV_R    = 2.0;   // rivet dome radius
PF_W    = 3.5;   // panel frame border width
PF_H    = 1.4;   // panel frame raise height

// Pi 4B actual dims
PI_W = 85; PI_D = 56; PI_H = 17;

// Derived
KB_CY = -CASE_D/2 + WALL + KB_FWD + KB_D/2; // keyboard center Y


// ============================================================
//  PRIMITIVE MODULES
// ============================================================

// True 45° chamfer on all 12 edges + 8 triangular corners
module cbox(w, d, h, c=CHAMP) {
    hull() {
        cube([w,     d-c*2, h-c*2], center=true);
        cube([w-c*2, d,     h-c*2], center=true);
        cube([w-c*2, d-c*2, h    ], center=true);
    }
}

// Brass dome rivet
module rivet() {
    color([0.82, 0.65, 0.22]) {
        cylinder(r=RV_R, h=0.9, $fn=14);
        translate([0,0,0.9]) sphere(r=RV_R, $fn=14);
    }
}
module rv_x(len, pitch=15) {
    n = max(2, floor(len/pitch));
    g = len/(n-1);
    for(i=[0:n-1]) translate([i*g - len/2, 0, 0]) rivet();
}
module rv_y(len, pitch=15) {
    n = max(2, floor(len/pitch));
    g = len/(n-1);
    for(i=[0:n-1]) translate([0, i*g - len/2, 0]) rivet();
}

// Raised panel border (sits on flat face, additive)
module pframe(w, d, fw=PF_W, fh=PF_H) {
    color([0.28, 0.30, 0.24])
    linear_extrude(fh)
        difference() {
            square([w, d], center=true);
            square([w-fw*2, d-fw*2], center=true);
        }
}

// Art deco concentric stepped frames (brass, additive)
module deco_steps(w, d, n=3, sw=3.8, maxh=2.8) {
    for(i=[0:n-1]) {
        iw = w - i*sw*2;
        id = d - i*sw*2;
        ih = maxh * (n-i) / n;
        if(iw > sw*2 && id > sw*2)
            color([0.78 + i*0.02, 0.58, 0.20])
            linear_extrude(ih)
                difference() {
                    square([iw, id], center=true);
                    square([iw-sw*0.75, id-sw*0.75], center=true);
                }
    }
}

// Hex bolt head (brass, decorative)
module bolt(r=3.2, h=2.4) {
    color([0.82, 0.65, 0.22]) cylinder(r=r, h=h, $fn=6);
}

// Diagonal vent slot array (subtractive)
module vent_cut(w, d, sw=2.2, pitch=5.5, ang=48) {
    intersection() {
        cube([w, d, 40], center=true);
        for(i=[-25:25])
            rotate([0,0,ang])
            translate([i*pitch, 0, 0])
                cube([sw, w+d+10, 40], center=true);
    }
}


// ============================================================
//  KEYBOARD  (40% staggered QWERTY visual)
// ============================================================
// Row layout bottom→top: stagger offset X, key count
ROW_STAG = [19.5, 12.5, 8.0, 0];   // X shift right per row
ROW_KEYS = [9,    11,   12,  12];   // key count per row

module keycap() {
    // Typewriter-style: tapered cylinder + dome top
    color([0.17, 0.14, 0.11]) {
        cylinder(r1=6.8, r2=5.8, h=3.2, $fn=16);
        translate([0,0,3.2]) sphere(r=5.8, $fn=16);
    }
}

module keyboard_visual() {
    // Plate
    color([0.24, 0.19, 0.15])
        translate([0,0,-1]) cube([KB_W+2, KB_D+2, 2.5], center=true);

    // Alpha rows (rows 1-3, skipping bottom row for spacebar treatment)
    for(r=[1:3]) {
        n  = ROW_KEYS[r];
        ox = ROW_STAG[r];
        ry = (r - 1.5) * KP;
        for(c=[0:n-1])
            translate([c*KP - (n-1)*KP/2 + ox/2, ry, 0])
                keycap();
    }

    // Bottom row: modifier + spacebar + modifiers
    ry0 = -1.5 * KP;
    n0  = ROW_KEYS[0];
    ox0 = ROW_STAG[0];
    for(c=[0:n0-1]) {
        cx = c*KP - (n0-1)*KP/2 + ox0/2;
        if(c < 2 || c > n0-3)
            translate([cx, ry0, 0]) keycap();           // mod keys
    }
    // Spacebar (5u wide)
    color([0.17,0.14,0.11])
    translate([ox0/2, ry0, 0]) {
        cylinder(r1=KP*2.8, r2=KP*2.5, h=3.2, $fn=24);
        translate([0,0,3.2]) sphere(r=KP*2.5, $fn=24);
    }
}


// ============================================================
//  HINGE BARREL
// ============================================================
module hinge_assy(is_base) {
    kl = HG_SPAN / HG_KNUC;
    for(k=[0:HG_KNUC-1]) {
        on_base = (k % 2 == 0);
        if(on_base == is_base) {
            cx = (k + 0.5 - HG_KNUC/2.0) * kl;
            color(is_base ? [0.50, 0.50, 0.54] : [0.44, 0.44, 0.48])
            translate([cx, 0, 0])
                rotate([90,0,0]) cylinder(d=HG_DIA, h=kl-1, center=true, $fn=30);
        }
    }
    // hinge pin line (thin)
    color([0.35,0.35,0.38])
    rotate([90,0,0]) cylinder(d=3, h=HG_SPAN, center=true, $fn=12);
}


// ============================================================
//  BOTTOM SHELL
// ============================================================
module _btm_ports() {
    py = CASE_D/2;
    pz = BTM_H/2 + 8;
    // USB-A ×2
    translate([-68, py, pz]) rotate([90,0,0]) cube([28,14,WALL*4], center=true);
    // USB 3 ×2
    translate([-32, py, pz]) rotate([90,0,0]) cube([28,14,WALL*4], center=true);
    // Ethernet
    translate([  6, py, pz]) rotate([90,0,0]) cube([18,13,WALL*4], center=true);
    // Micro-HDMI ×2
    translate([ 28, py, pz]) rotate([90,0,0]) cube([10, 6,WALL*4], center=true);
    translate([ 40, py, pz]) rotate([90,0,0]) cube([10, 6,WALL*4], center=true);
    // USB-C power
    translate([ 55, py, pz]) rotate([90,0,0]) cube([10, 5,WALL*4], center=true);
    // 3.5mm jack
    translate([ 70, py, pz]) rotate([90,0,0]) cylinder(r=3.2, h=WALL*4, center=true);
    // MicroSD — left side near front
    translate([-CASE_W/2, -CASE_D/2+16, BTM_H/2+4])
        rotate([0,90,0]) cube([4,14,WALL*4], center=true);
}

module _btm_top_surface() {
    tz = BTM_H;
    // Stepped deco frame around keyboard
    translate([0, KB_CY, tz])
        deco_steps(KB_W+18, KB_D+18, n=3, sw=3.8, maxh=2.4);
    // Raised panel frames — flanking keyboard
    for(sx=[-1,1])
        translate([sx*(KB_W/2+14), KB_CY, tz])
            pframe(18, KB_D+2);
    // Wrist ledge panel
    translate([0, -CASE_D/2+WALL+KB_FWD/2, tz])
        pframe(KB_W+22, KB_FWD-4);
    // Rivet rows around keyboard
    translate([0, KB_CY-KB_D/2-10, tz+0.4]) rv_x(KB_W+8,  19);
    translate([0, KB_CY+KB_D/2+10, tz+0.4]) rv_x(KB_W+8,  19);
    translate([-KB_W/2-9, KB_CY,   tz+0.4]) rv_y(KB_D,    17);
    translate([ KB_W/2+9, KB_CY,   tz+0.4]) rv_y(KB_D,    17);
    // Corner bolts
    for(bx=[-CASE_W/2+10, CASE_W/2-10])
    for(by=[-CASE_D/2+10, CASE_D/2-10])
        translate([bx, by, tz]) bolt(3.5, 2.6);
}

module _btm_front_surface() {
    fy = -CASE_D/2;
    fz =  BTM_H/2;
    // Main panel frame
    translate([0, fy, fz]) rotate([90,0,0])
        pframe(CASE_W-24, BTM_H-14);
    // Decorative latch — centre front
    translate([0, fy-0.5, fz]) rotate([90,0,0]) {
        bolt(5.5, 3.8);
        // bail ring
        color([0.82,0.65,0.22])
        translate([0,0,3.8]) rotate([90,0,0])
            rotate_extrude(angle=180, $fn=24)
                translate([5.8,0]) circle(r=1.6, $fn=10);
    }
    // Rivet rows top and bottom of front face
    translate([0, fy, BTM_H-8]) rv_x(CASE_W-30, 18);
    translate([0, fy,        8]) rv_x(CASE_W-30, 18);
}

module _btm_side_surfaces() {
    for(sx=[-1,1]) {
        sx_pos = sx*CASE_W/2;
        fz     = BTM_H/2;
        // Panel frame
        translate([sx_pos, 0, fz]) rotate([0,-sx*90,0])
            pframe(CASE_D-20, BTM_H-16);
        // Rivet rows
        translate([sx_pos, 0, BTM_H-8]) rv_y(CASE_D-24, 17);
        translate([sx_pos, 0,        8]) rv_y(CASE_D-24, 17);
        // Small bolts at midpoints
        for(by=[-CASE_D/4, CASE_D/4])
            translate([sx_pos, by, fz]) rotate([0,-sx*90,0]) bolt(2.8,2.0);
    }
}

module bottom_shell() {
    color([0.20, 0.23, 0.18])
    difference() {
        translate([0,0,BTM_H/2]) cbox(CASE_W, CASE_D, BTM_H);
        // Interior hollow
        translate([0, 0, WALL+(BTM_H-WALL)/2])
            cube([CASE_W-WALL*2, CASE_D-WALL*2, BTM_H], center=true);
        // Keyboard well (open top)
        translate([0, KB_CY, BTM_H-WALL/2])
            cube([KB_W+1.5, KB_D+1.5, WALL+2], center=true);
        // Port cutouts
        _btm_ports();
        // Front vent
        translate([0, -CASE_D/2, BTM_H*0.38])
        rotate([90,0,0]) vent_cut(CASE_W-60, 14);
        // Side vents
        for(sx=[-1,1])
        translate([sx*CASE_W/2, 8, BTM_H*0.40])
        rotate([0,-sx*90,0]) vent_cut(CASE_D-30, 16, sw=1.8, pitch=4.5);
    }
    // Surface details
    _btm_top_surface();
    _btm_front_surface();
    _btm_side_surfaces();
    // Hinge knuckles (base side = even knuckles)
    translate([0, CASE_D/2, BTM_H]) hinge_assy(is_base=true);
}


// ============================================================
//  TOP LID  (screen half)
//  Coordinate origin = hinge line = [Y=+CASE_D/2, Z=0]
//  Inner face (screen) at Z=0  |  Outer/decor face at Z=TOP_H
// ============================================================
module _lid_inner_face() {
    // Stepped deco bezel around screen
    translate([0, 0, 0])
        deco_steps(SCR_W+22, SCR_H+22, n=4, sw=3.5, maxh=3.2);
    // Rivet rows around screen bezel
    translate([0, -SCR_H/2-11, 0.4]) rv_x(SCR_W+14, 19);
    translate([0,  SCR_H/2+11, 0.4]) rv_x(SCR_W+14, 19);
    for(sx=[-1,1])
        translate([sx*(SCR_W/2+11), 0, 0.4]) rv_y(SCR_H+6, 17);
    // Corner bolts on bezel
    for(bx=[-SCR_W/2-7, SCR_W/2+7])
    for(by=[-SCR_H/2-7, SCR_H/2+7])
        translate([bx, by, 0]) bolt(3.0, 2.6);
}

module _lid_outer_face() {
    // Central art deco motif — concentric stepped rectangles
    // rising to a brass peak (visible as decor on side table)
    for(i=[0:7]) {
        iw = 86 - i*8.5;
        id = 58 - i*5.5;
        ih = 0.8 + i*0.52;
        if(iw > 6 && id > 6)
            color([0.72+i*0.015, 0.54+i*0.008, 0.18])
            linear_extrude(ih)
                difference() {
                    square([iw, id], center=true);
                    square([max(1,iw-5.5), max(1,id-5.5)], center=true);
                }
    }
    // Outer border panel
    pframe(CASE_W-16, CASE_D-16, fw=PF_W+1, fh=2.0);
    // Inner deco step border
    deco_steps(CASE_W-32, CASE_D-32, n=3, sw=4.0, maxh=2.6);
    // Perimeter rivet rows
    translate([0, -CASE_D/2+11, 0.4]) rv_x(CASE_W-30, 17);
    translate([0,  CASE_D/2-11, 0.4]) rv_x(CASE_W-30, 17);
    for(sx=[-1,1])
        translate([sx*(CASE_W/2-11), 0, 0.4]) rv_y(CASE_D-24, 17);
    // Corner bolts
    for(bx=[-CASE_W/2+10, CASE_W/2-10])
    for(by=[-CASE_D/2+10, CASE_D/2-10])
        translate([bx, by, 0]) bolt(3.5, 2.6);
}

module top_lid() {
    // Body
    color([0.21, 0.24, 0.19])
    difference() {
        translate([0,0,TOP_H/2]) cbox(CASE_W, CASE_D, TOP_H);
        // Screen cavity from inner face
        translate([0, 0, -EPS])
            cube([SCR_W, SCR_H, SCR_D+EPS+0.5], center=true);
        // Screen cable/board relief further in
        translate([0, 0, SCR_D])
            cube([SCR_W-10, SCR_H-10, TOP_H], center=true);
    }
    // Screen glass (semi-transparent blue)
    color([0.07, 0.11, 0.32, 0.80])
    translate([0, 0, 0.6]) cube([SCR_W-2, SCR_H-2, 1.4], center=true);
    // Inner face details (screen side)
    translate([0, 0, 0]) _lid_inner_face();
    // Outer face details (decor side)
    translate([0, 0, TOP_H]) _lid_outer_face();
    // Front edge latch receiver
    translate([0, -CASE_D/2-0.5, TOP_H/2]) rotate([90,0,0])
        bolt(5.5, 3.8);
    // Front edge rivets
    translate([0, -CASE_D/2, TOP_H-6]) rv_x(CASE_W-30, 17);
    translate([0, -CASE_D/2,       6]) rv_x(CASE_W-30, 17);
    // Side edge rivets
    for(sx=[-1,1]) {
        translate([sx*CASE_W/2, 0, TOP_H-6]) rv_y(CASE_D-24, 17);
        translate([sx*CASE_W/2, 0,       6]) rv_y(CASE_D-24, 17);
    }
    // Hinge knuckles (lid side = odd knuckles)
    translate([0, CASE_D/2, 0]) hinge_assy(is_base=false);
}


// ============================================================
//  RASPBERRY PI 4B  (reference only — shows placement)
// ============================================================
module raspberry_pi() {
    color([0.11, 0.38, 0.11]) {
        cube([PI_W, PI_D, 2], center=true);
        translate([-PI_W/2+13, -PI_D/2+9,  5]) cube([26,15,12],center=true);
        translate([-PI_W/2+13, -PI_D/2+27, 5]) cube([26,15,12],center=true);
        translate([-PI_W/2+13,  PI_D/2-12, 5]) cube([22,17,12],center=true);
        translate([ PI_W/2-14, -PI_D/2+11, 2]) cube([16, 8, 5],center=true);
        translate([ PI_W/2-28, -PI_D/2+11, 2]) cube([16, 8, 5],center=true);
        translate([ PI_W/2-38, -PI_D/2+11, 2]) cube([ 8, 5, 4],center=true);
        translate([ PI_W/2-16,  PI_D/2-5,  4]) cube([52, 5, 8],center=true);
        translate([0, 4, 4]) cube([16,16,6],center=true);
    }
    color([0.58,0.58,0.58])
    translate([0, 4, 7]) cube([19,19,5],center=true);
}


// ============================================================
//  ASSEMBLY
// ============================================================
if(SHOW_BASE) {
    bottom_shell();
    // Keyboard in its well
    if(SHOW_KEYS)
        translate([0, KB_CY, BTM_H-WALL+1.5])
            keyboard_visual();
    // Pi reference (rear, below keyboard plate)
    if(SHOW_PI)
        translate([PI_W/2-5, CASE_D/2-PI_D-10, WALL+PI_H/2])
            raspberry_pi();
}

if(SHOW_LID) {
    // Pivot around hinge line at world [0, CASE_D/2, BTM_H]
    translate([0, CASE_D/2, BTM_H])
    rotate([-LID_OPEN, 0, 0])
    translate([0, -CASE_D/2, 0])
        top_lid();
}


// ============================================================
//  CONSOLE INFO
// ============================================================
echo("────────────────────────────────────────");
echo(str("Footprint (closed): ", CASE_W, " × ", CASE_D, " × ", BTM_H+TOP_H, " mm"));
echo(str("Keyboard bay: ", KB_W, " × ", KB_D, " mm  (40%, 12×4, KP=", KP, "mm)"));
echo(str("Screen: 5\"  ", SCR_W, " × ", SCR_H, " mm"));
echo(str("Lid angle: ", LID_OPEN, "°  (change LID_OPEN to preview other angles)"));
echo("────────────────────────────────────────");
echo("PRINT PARTS (both fit P1S 256³ flat):");
echo("  1 — Base shell  218 × 118 × 44 mm — print opening-face-up");
echo("  2 — Lid         218 × 118 × 20 mm — print decor-face-down");
echo("────────────────────────────────────────");
