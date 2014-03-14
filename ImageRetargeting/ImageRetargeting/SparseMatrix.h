#import "Matrix.h"

@interface SparseMatrix : Matrix {
    @protected
    NSMutableArray * data;

}
// initialization
-(SparseMatrix *)initWithSizeRows:(int)aRows andColumns:(int)aColumns;

// access
-(double)entryAtRow:(int)row andColumn:(int)column;
-(void)setEntryAtRow:(int)row andColumn:(int)column toValue:(double)value;

@end
