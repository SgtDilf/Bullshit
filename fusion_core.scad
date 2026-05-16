// ============================================================
//  FALLOUT 4 — FUSION CORE  |  1:1 Scale Prop Replica
//  Approx real-world dims: ~76mm dia × 132mm tall
//  Print vertically — split at mid-seam for FDM
// ============================================================

$fn = 72;

// ─── SCALE ──────────────────────────────────────────────────
SCALE = 1.0;   // 1.0 = full size  |  0.5 = desktop miniature

function S(v) = v * SCALE;

// ─── DIMENSIONS ─────────────────────────────────────────────
BODY_R      = S(38);    // main body radius
BOT_R       = S(27);    // bottom plug radius
CAP_R       = S(36);    // top cap radius
TOTAL_H     = S(132);

// Section Z positions (from bottom)
Z0  =  S(0);    // base of plug
Z1  =  S(16);   // top of plug shaft
Z2  =  S(22);   // top of plug-to-body transition cone
Z3  =  S(56);   // bottom of band 1
Z4  =  S(65);   // top of band 1
Z5  =  S(105);  // bottom of band 2
Z6  =  S(113);  // top of band 2
Z7  =  S(126);  // bottom of cap dome
Z8  =  S(132);  // apex

// Detail sizes
FIN_H    = S(3.2);   // fin protrusion radially
FIN_W    = S(6.5);   // fin width (arc)
GROOVE_D = S(1.0);   // groove cut depth
BAND_OVR = S(3.5);   // band overhang beyond body radius

// ─── COLOURS ────────────────────────────────────────────────
C_BODY = [0.62, 0.55, 0.34];          // weathered brass / tan
C_BAND = [0.26, 0.26, 0.28];          // dark steel collar
C_PLUG = [0.20, 0.19, 0.18];          // black contact housing
C_FIN  = [0.54, 0.48, 0.30];          // slightly darker fin
C_LENS = [0.10, 0.88, 0.22, 0.78];   // glowing green (alpha!)
C_RIM  = [0.38, 0.35, 0.28];          // rim ring brass
C_DIRT = [0.18, 0.17, 0.15];          // dark grime accent


// ============================================================
//  HELPERS
// ============================================================

// Thin groove ring cut around cylinder at given Z/R
module groove_ring(r, z, depth=GROOVE_D, width=1.8) {
    translate([0,0,z])
    rotate_extrude()
        translate([r - depth, -width/2])
            square([depth + 1, width]);
}

// Raised ring band (additive)
module raise_ring(r, z, h=2, thick=2.5) {
    translate([0,0,z])
    rotate_extrude()
        translate([r, 0])
            square([thick, h]);
}


// ============================================================
//  BOTTOM CONTACT PLUG
// ============================================================
module bottom_plug() {
    color(C_PLUG)
    union() {
        // Hexagonal contact socket face (very bottom)
        cylinder(r=BOT_R - 6, h=S(3), $fn=6);

        // Plug shaft with three contact bands
        difference() {
            cylinder(r=BOT_R, h=Z1);
            // Flat cuts on two sides (orientation key)
            for(sx=[-1,1])
                translate([sx*(BOT_R - S(3)), -BOT_R, 0])
                    cube([S(4), BOT_R*2, Z1*0.6]);
        }

        // Three raised contact rings
        for(z=[S(4), S(8.5), S(13)])
            raise_ring(BOT_R, z, h=S(2.5), thick=S(2.8));

        // Knurled grip texture hint (segmented rings)
        for(z=[S(3.5), S(5.5), S(7.5), S(9.5), S(11.5)])
            color(C_DIRT)
            translate([0,0,z])
            rotate_extrude()
                translate([BOT_R - S(0.8), 0])
                    square([S(1), S(1.2)]);

        // Transition cone → main body diameter
        translate([0,0,Z1])
            cylinder(r1=BOT_R, r2=BODY_R, h=Z2-Z1);
    }
}


// ============================================================
//  COLLAR BANDS
// ============================================================
module collar_band(z_bot, h, r=BODY_R, ovr=BAND_OVR) {
    color(C_BAND)
    translate([0,0,z_bot])
    difference() {
        union() {
            // Main collar ring
            cylinder(r=r + ovr, h=h);
            // Raised lip at top and bottom edge
            raise_ring(r+ovr, 0,   h=S(1.8), thick=S(1.5));
            raise_ring(r+ovr, h-S(1.8), h=S(1.8), thick=S(1.5));
        }
        // Hollow interior (sits over body cylinder)
        translate([0,0,-1]) cylinder(r=r - S(0.5), h=h+2);
        // Centre groove (visual depth)
        translate([0,0,h/2])
        rotate_extrude()
            translate([r + ovr + S(0.5), -S(1)])
                square([S(2.5), S(2)]);
    }
    // Small bolt bosses around the band
    color(C_RIM)
    translate([0,0,z_bot+h/2])
    for(i=[0:5])
        rotate([0,0,i*60])
        translate([r+ovr-S(0.5), 0, 0])
        rotate([0,90,0])
            cylinder(r=S(2.2), h=S(1.5), $fn=6);
}


// ============================================================
//  VERTICAL FINS  (6 evenly spaced)
// ============================================================
module single_fin(r, z_bot, z_top) {
    len = z_top - z_bot;
    fw  = FIN_W;
    fh  = FIN_H;

    translate([r, -fw/2, z_bot])
    difference() {
        union() {
            // Main fin block
            cube([fh, fw, len]);
            // Chamfered leading edge (top taper)
            translate([0, 0, len - S(8)])
                cube([fh*0.6, fw, S(8)]);
        }
        // Taper top of fin to a ridge
        translate([-S(0.1), -S(0.1), len - S(12)])
            rotate([0, -15, 0])
                cube([fh*2, fw+S(0.2), S(20)]);
        // Chamfer bottom
        translate([-S(0.1), -S(0.1), -S(8)])
            rotate([0, 15, 0])
                cube([fh*2, fw+S(0.2), S(10)]);
    }
}

module all_fins() {
    color(C_FIN)
    for(i=[0:5])
        rotate([0,0, i*60])
            single_fin(BODY_R, Z2 + S(4), Z3 - S(2));
}


// ============================================================
//  MAIN BODY CYLINDER  (lower + upper sections)
// ============================================================
module main_body() {
    color(C_BODY)
    difference() {
        union() {
            // Lower body (Z2 → Z3)
            translate([0,0,Z2]) cylinder(r=BODY_R, h=Z3-Z2);
            // Upper body (Z4 → Z5)
            translate([0,0,Z4]) cylinder(r=BODY_R, h=Z5-Z4);
        }

        // ── Horizontal panel grooves (lower body) ────────────
        for(z=[Z2+S(8), Z2+S(18), Z2+S(28)])
            groove_ring(BODY_R, z);

        // ── Vertical recessed slots between fins (lower) ─────
        // 6 slots, offset 30° from fins
        for(i=[0:5])
            rotate([0,0, i*60+30])
            translate([BODY_R-GROOVE_D, -S(0.7), Z2])
                cube([GROOVE_D+S(1), S(1.4), Z3-Z2]);

        // ── Upper body panel grooves ──────────────────────────
        for(z=[Z4+S(10), Z4+S(24), Z4+S(38)])
            groove_ring(BODY_R, z);

        // ── Six recessed rectangular panels (upper body) ──────
        for(i=[0:5])
            rotate([0,0,i*60])
            translate([BODY_R-GROOVE_D-S(0.5), -S(7), Z4+S(6)])
                cube([GROOVE_D+S(1), S(14), Z5-Z4-S(14)]);

        // ── Vent slots on upper body (between panel rects) ────
        for(i=[0:5])
            rotate([0,0,i*60+30])
            translate([BODY_R-S(1.5), -S(4), Z4+S(28)])
                cube([S(2.5), S(8), S(12)]);
    }

    // Raised panel borders on upper body rects
    color(C_RIM)
    for(i=[0:5])
        rotate([0,0,i*60])
        translate([BODY_R+S(0.2), 0, Z4+S(20)])
        rotate([0,90,0])
        rotate([0,0,90])
            linear_extrude(S(0.8))
                difference() {
                    square([S(22), S(14)], center=true);
                    square([S(18), S(10)], center=true);
                }
}


// ============================================================
//  TOP CAP ASSEMBLY
// ============================================================

// Distance between centres for flat-top adjacent hexagons
// with circumradius R1 and R2, touching + gap G
function hex_dist(r1, r2, gap=S(1.5)) =
    (r1 + r2) * sqrt(3)/2 + gap / cos(30);

module hex_eye_recess(depth=S(3)) {
    cr  = S(12.5);  // central hex circumradius
    sr  = S(9.2);   // surrounding hex circumradius
    cd  = hex_dist(cr, sr, S(1.8));  // centre distance

    translate([0,0,-S(0.1)]) {
        // Central hex well
        cylinder(r=cr, h=depth+S(0.1), $fn=6);
        // 6 surrounding hex wells
        for(i=[0:5])
            rotate([0,0, i*60+30])
            translate([cd, 0, 0])
                cylinder(r=sr, h=depth+S(0.1), $fn=6);
        // Thin connecting groove between centre and each outer hex
        for(i=[0:5])
            rotate([0,0, i*60+30])
            translate([cr, -S(0.5), 0])
                cube([cd-cr-sr, S(1), depth+S(0.1)]);
    }
}

module hex_lens() {
    cr = S(12.5);
    sr = S(9.2);
    cd = hex_dist(cr, sr, S(1.8));

    color(C_LENS)
    translate([0,0,Z8 - S(2.8)]) {
        // Central lens — fills recess + tiny dome
        cylinder(r=cr-S(0.3), h=S(3.2), $fn=6);
        translate([0,0,S(3.2)]) sphere(r=S(3.8), $fn=32);

        // 6 outer lenses
        for(i=[0:5])
            rotate([0,0, i*60+30])
            translate([cd, 0, 0]) {
                cylinder(r=sr-S(0.3), h=S(2.5), $fn=6);
                translate([0,0,S(2.5)]) sphere(r=S(2.8), $fn=24);
            }
    }
}

module top_cap() {
    color(C_BODY)
    difference() {
        union() {
            // Lower cap taper (band 2 top → dome base)
            translate([0,0,Z6])
                cylinder(r1=BODY_R, r2=CAP_R, h=Z7-Z6);
            // Dome section
            translate([0,0,Z7])
                cylinder(r1=CAP_R, r2=CAP_R-S(3), h=Z8-Z7);
        }
        // Hex eye recess
        translate([0,0,Z8-S(3)])
            hex_eye_recess(S(3.5));

        // Circular groove around cap perimeter
        groove_ring(CAP_R-S(2), Z6+S(4));
        groove_ring(CAP_R-S(2), Z6+S(8));

        // 6 small bolt-hole indents around cap rim
        for(i=[0:5])
            rotate([0,0,i*60])
            translate([CAP_R-S(4), 0, Z6+S(3)])
                cylinder(r=S(2), h=S(2));
    }

    // Raised ring at cap base
    color(C_RIM)
    raise_ring(CAP_R+S(0.5), Z6, h=S(3), thick=S(2));

    // 6 hex bolts around cap rim
    color(C_RIM)
    for(i=[0:5])
        rotate([0,0,i*60])
        translate([CAP_R-S(4), 0, Z6+S(3)])
            cylinder(r=S(2), h=S(1.5), $fn=6);
}


// ============================================================
//  ASSEMBLY
// ============================================================
bottom_plug();
main_body();
all_fins();
collar_band(Z3, Z4-Z3);
collar_band(Z5, Z6-Z5);
top_cap();
hex_lens();


// ============================================================
//  INFO
// ============================================================
echo("─────────────────────────────────");
echo(str("Fusion Core: ⌀", BODY_R*2, "mm × ", TOTAL_H, "mm tall"));
echo(str("Scale: ", SCALE*100, "%  (1.0 = full size prop)"));
echo("─────────────────────────────────");
echo("Adjust SCALE at top of file:");
echo("  1.0  = full prop (76 × 132 mm)");
echo("  0.5  = desk miniature");
echo("  1.25 = oversized display piece");
echo("─────────────────────────────────");
