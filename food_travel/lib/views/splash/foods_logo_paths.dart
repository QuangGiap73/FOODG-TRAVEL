import 'package:flutter/material.dart';

/// Logo geometry in the 1254 x 1254 coordinate system of the reference SVG.
abstract final class FoodsLogoPaths {
  static final Path steamLeftPath =
      Path()
        ..moveTo(536, 99)
        ..cubicTo(557, 131, 555, 165, 535, 199)
        ..cubicTo(522, 220, 499, 239, 491, 267)
        ..cubicTo(484, 288, 488, 307, 495, 325)
        ..cubicTo(470, 309, 459, 289, 461, 253)
        ..cubicTo(463, 229, 474, 211, 491, 192)
        ..cubicTo(523, 158, 535, 137, 536, 99)
        ..close();

  static final Path steamRightPath =
      Path()
        ..moveTo(599, 202)
        ..cubicTo(617, 226, 618, 250, 607, 274)
        ..cubicTo(600, 290, 586, 305, 575, 320)
        ..cubicTo(564, 336, 563, 355, 568, 376)
        ..cubicTo(549, 362, 542, 345, 544, 318)
        ..cubicTo(547, 298, 555, 288, 570, 270)
        ..cubicTo(590, 247, 598, 229, 599, 202)
        ..close();

  static final Path sGuidePath =
      Path()
        ..moveTo(780, 430)
        ..cubicTo(706, 444, 557, 469, 493, 512)
        ..cubicTo(441, 547, 449, 593, 510, 625)
        ..cubicTo(554, 648, 624, 661, 690, 680)
        ..cubicTo(812, 715, 864, 774, 831, 839)
        ..cubicTo(794, 910, 690, 927, 591, 923)
        ..cubicTo(499, 920, 405, 900, 326, 875);

  static final Path sFinalShapePath =
      Path()
        ..moveTo(790, 424)
        ..cubicTo(773, 414, 758, 414, 717, 424)
        ..cubicTo(628, 432, 548, 443, 490, 459)
        ..cubicTo(423, 478, 383, 518, 383, 565)
        ..lineTo(383, 593)
        ..cubicTo(389, 631, 416, 659, 461, 679)
        ..cubicTo(499, 696, 554, 708, 609, 721)
        ..cubicTo(683, 739, 718, 768, 731, 797)
        ..cubicTo(746, 832, 713, 871, 661, 881)
        ..cubicTo(566, 903, 446, 879, 342, 862)
        ..cubicTo(326, 859, 312, 863, 309, 871)
        ..cubicTo(304, 887, 339, 901, 379, 916)
        ..cubicTo(459, 944, 565, 955, 642, 950)
        ..cubicTo(773, 943, 872, 900, 900, 835)
        ..cubicTo(925, 776, 880, 722, 785, 685)
        ..cubicTo(745, 670, 701, 660, 658, 651)
        ..cubicTo(572, 632, 516, 605, 516, 562)
        ..cubicTo(516, 521, 574, 487, 643, 477)
        ..cubicTo(714, 459, 765, 448, 785, 435)
        ..cubicTo(789, 432, 791, 427, 790, 424)
        ..close();

  static final Path bowlTopPath =
      Path()
        ..moveTo(276, 874)
        ..cubicTo(335, 928, 459, 965, 594, 981)
        ..cubicTo(714, 984, 823, 955, 894, 894);

  static final Path bowlBodyPath =
      Path()
        ..moveTo(275, 874)
        ..cubicTo(283, 956, 331, 1020, 400, 1065)
        ..cubicTo(454, 1101, 519, 1118, 594, 1116)
        ..cubicTo(673, 1117, 744, 1092, 793, 1045)
        ..cubicTo(841, 1000, 875, 945, 894, 894)
        ..cubicTo(827, 952, 722, 980, 594, 981)
        ..cubicTo(458, 981, 335, 943, 275, 874)
        ..close();

  static final Path bowlCutoutPath =
      Path()
        ..moveTo(298, 899)
        ..cubicTo(414, 971, 548, 990, 666, 979)
        ..cubicTo(755, 973, 827, 946, 881, 906);

  static final Path routePath =
      Path()
        ..moveTo(621, 568)
        ..cubicTo(638, 543, 670, 526, 711, 517)
        ..cubicTo(760, 506, 806, 496, 828, 461)
        ..cubicTo(839, 445, 838, 432, 837, 420);

  static final Path routeTailPath =
      Path()
        ..moveTo(621, 568)
        ..cubicTo(624, 594, 653, 611, 692, 623)
        ..cubicTo(718, 631, 743, 641, 765, 651);

  static final Path locationPinPath =
      Path()
        ..moveTo(826, 242)
        ..cubicTo(797, 247, 777, 268, 777, 300)
        ..cubicTo(777, 333, 799, 362, 834, 402)
        ..cubicTo(838, 404, 840, 402, 845, 395)
        ..cubicTo(878, 358, 895, 331, 895, 300)
        ..cubicTo(895, 267, 873, 244, 848, 242)
        ..close();

  static const decorationDots = <(Offset, double)>[
    (Offset(836, 643), 10),
    (Offset(946, 817), 11),
  ];
}
