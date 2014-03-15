//
//  CVXRangeGenSolver25x25+Util.h
//  CVXSolver
//
/* Produced by CVXGEN, 2012-11-27 15:57:37 -0800.  */
/* CVXGEN is Copyright (C) 2006-2011 Jacob Mattingley, jem@cvxgen.com. */
/* The code in this file is Copyright (C) 2006-2011 Jacob Mattingley. */
/* CVXGEN, or solvers produced by CVXGEN, cannot be used for commercial */
/* applications without prior written permission from Jacob Mattingley. */

#import "CVXGenRangeSolver25x25.h"

@interface CVXGenRangeSolver25x25 (Util)
/* Function definitions in /home/jem/olsr/releases/20110330074202/lib/olsr.extra/qp_solver/util.c: */
-(void) tic;
-(float) toc;
-(int) int_toc;
-(float) tocq;
-(void) printmatrixWithName:(char *)name A:(double *)A m:(int)m n:(int)n andSparse:(int) sparse;
-(double) unifWithLower:(double)lower andUpper:(double)upper;
-(float) ran1WithIdum:(long*)idum andReset:(int)reset;
-(float) randn_internalWithIdum:(long *)idum andReset:(int)reset;
-(double) randn;
-(void) reset_rand;
@end
