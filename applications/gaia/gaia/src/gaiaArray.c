/*+
 *   Name:
 *      gaiaArray

 *   Purpose:
 *      Utility routines for handling arrays.

 *   Language:
 *      C

 *  Copyright:
 *     Copyright (C) 2006 Particle Physics and Astronomy Research Council

 *   Authors:
 *      PWD: Peter W. Draper, Starlink - University of Durham

 *   History:
 *      23-MAR-2006 (PWD):
 *         Original version.
 *      {enter_changes_here}
 *-
 */
#include <sys/types.h>
#include <stdlib.h>

#include <gaiaArray.h>
#include <prm_par.h>
#include <cnf.h>

/**
 * Convert an HDS data type into a local enum value. Returns HDS_UNKNOWN if
 * the type cannot be understood (should be _BYTE, _UBYTE, _WORD, _UWORD,
 * _INTEGER, _REAL or _DOUBLE, case-insentive allowed and truncation to
 * uniqueness).
 */
int gaiaArrayHDSType( char *typePtr )
{
    int type = HDS_UNKNOWN;

    if ( typePtr[0] == '_' ) {
        if ( typePtr[1] == 'u' || typePtr[1] == 'U' ) {
            if ( typePtr[2] == 'b' || typePtr[2] == 'B' ) {
                type = HDS_UBYTE;
            }
            else if ( typePtr[2] == 'w' || typePtr[2] == 'W' ) {
                type = HDS_UWORD;
            }
        }
        else if ( typePtr[1] == 'b' || typePtr[1] == 'B' ) {
            type = HDS_BYTE;
        }
        else if ( typePtr[1] == 'w' || typePtr[1] == 'W' ) {
            type = HDS_WORD;
        }
        else if ( typePtr[1] == 'i' || typePtr[1] == 'I' ) {
            type = HDS_INTEGER;
        }
        else if ( typePtr[1] == 'r' || typePtr[1] == 'R' ) {
            type = HDS_REAL;
        }
        else if ( typePtr[1] == 'd' || typePtr[1] == 'D' ) {
            type = HDS_DOUBLE;
        }
    }
    return type;
}

/**
 *  Return the sizeof() of a known type.
 */
static size_t gaiaArraySizeOf( int type )
{
    switch ( type )
    {
        case HDS_DOUBLE :
            return sizeof( double );

        case HDS_REAL :
            return sizeof( float );

        case HDS_INTEGER :
            return sizeof( int );

        case HDS_WORD :
            return sizeof( short );

        case HDS_UWORD :
            return sizeof( unsigned short );

        case HDS_BYTE :
            return sizeof( char );

    }
    /* Default, HDS_UBYTE */
    return sizeof( unsigned char );
}

/**
 *  Convert an array from a supported type into double precision. Any BAD
 *  values to be replaced with the given value.
 */
void gaiaArrayToDouble( void *inPtr, int nel, int type, double badValue,
                        double *outPtr )
{

    /* Define loop as macro to save typing and maintenance */
#define CONVERT_AND_COPY(type,badFlag)    \
{                                         \
    double *dataPtr = outPtr;             \
    int i;                                \
    type *fromPtr = (type *) inPtr;       \
    type value;                           \
    for ( i = 0; i < nel; i++ ) {         \
        value = *fromPtr++;               \
        if ( value == badFlag ) {         \
            *dataPtr++ = badValue;        \
        }                                 \
        else {                            \
            *dataPtr++ = (type) value;    \
        }                                 \
    }                                     \
}
    switch ( type )
    {
        case HDS_DOUBLE:
            CONVERT_AND_COPY(double,VAL__BADD)
        break;

        case HDS_REAL:
            CONVERT_AND_COPY(float,VAL__BADD)
        break;

        case HDS_INTEGER:
            CONVERT_AND_COPY(int,VAL__BADI)
        break;

        case HDS_WORD:
            CONVERT_AND_COPY(short,VAL__BADW)
        break;

        case HDS_UWORD:
            CONVERT_AND_COPY(unsigned short,VAL__BADUW)
        break;

        case HDS_BYTE:
            CONVERT_AND_COPY(char,VAL__BADB)
        break;

        case HDS_UBYTE:
            CONVERT_AND_COPY(unsigned char,VAL__BADUB)
        break;
    }
#undef CONVERT_AND_COPY
}

/**
 *  Name:
 *     gaiaArrayImageFromCube
 *
 *  Purpose:
 *     Given an array of 3 significant dimensions, in a supported data type,
 *     extract a 2D image section and return the data in that section. The
 *     dataType should be one of the enumerations HDS_ defined in gaiaArray.h
 *     (these correspond to the HDS data types).
 *
 *  Arguments:
 *     inPtr
 *         Pointer to the cube.
 *     type
 *         The data type (HDS_?).
 *     dims[3]
 *         The dimensions of the cube.
 *     axis
 *         The axis that will be lost. One of 0, 1, 2. Losing the last axis is
 *         fastest.
 *     index
 *         The index of the plane that will be extracted (along axis "axis").
 *     outPtr
 *         a pointer to a pointer that will point at the extracted image on
 *         exit. This memory is allocated using malloc or cnfMalloc as
 *         determined by the final argument. Freeing it is the responsibility
 *         of the caller.
 *     cnfmalloc
 *         Whether to use cnfMalloc to allocate the image data. Otherwise
 *         malloc will be used.
 */
void gaiaArrayImageFromCube( void *inPtr, char type, int dims[3],
                             int axis, int index, void **outPtr,
                             int cnfmalloc )
{
    if ( axis == 2 ) {

        /* If we're losing the last dimension, then this is just a memcpy. */
        char *ptr;
        size_t length;
        size_t nel;
        size_t offset;

        nel = (size_t) dims[0] * (size_t) dims[1];
        length = nel * gaiaArraySizeOf( type );

        if ( cnfmalloc == 1 ) {
            *outPtr = cnfMalloc( length );
        }
        else {
            *outPtr = malloc( length );
        }

        /* Get the offset into cube of first pixel */
        offset = (size_t) index * (size_t) dims[0] * (size_t) dims[1];
        ptr = ((char *) inPtr) + offset;

        /* And copy the memory */
        memcpy( *outPtr, ptr, length );
    }
    else {

        /* Noncontiguous memory, so need to pick it out pixel by pixel */
        int axis1;
        int axis2;
        int i;
        int indices[3];
        int j;
        int k;
        int l;
        int offset;
        int strides[3];
        size_t length;
        size_t nel;

        /* Pick out axes we're keeping and set the index of the image to pick
         * out along axis "axis" */
        indices[axis] = index;
        if ( axis == 0 ) {
            axis1 = 1;
            axis2 = 2;
        }
        else {
            axis1 = 0;
            axis2 = 2;
        }

        /* Allocate the memory */
        nel = (size_t) dims[axis1] * (size_t) dims[axis2];
        length = nel * gaiaArraySizeOf( type );;

        if ( cnfmalloc == 1 ) {
            *outPtr = cnfMalloc( length );
        }
        else {
            *outPtr = malloc( length );
        }

        /* Get the strides for stepping around dimensions */
        gaiaArrayGetStrides( 3, dims, strides );

        /* Copy the image, use type switch to keep pointer arithmetic simple.
         * Use a macro to keep repeated code under control */
#define EXTRACT_AND_COPY(type)                    \
{                                                 \
    type *fromPtr = (type *) inPtr;               \
    type *toPtr = (type *) *outPtr;               \
    k = 0;                                        \
    for ( i = 0; i < dims[axis2]; i++ ) {         \
        indices[axis2] = i;                       \
        for ( j = 0; j < dims[axis1]; j++ ) {     \
            indices[axis1] = j;                   \
            offset = 0;                           \
            for ( l = 0; l < 3; l++ ) {           \
                offset += strides[l] * indices[l];\
            }                                     \
            toPtr[k] = fromPtr[offset];           \
        }                                         \
    }                                             \
}
        switch ( type )
        {
            case HDS_DOUBLE:
                EXTRACT_AND_COPY(double)
            break;

            case HDS_REAL:
                EXTRACT_AND_COPY(float)
            break;

            case HDS_INTEGER:
                EXTRACT_AND_COPY(int)
            break;

            case HDS_WORD:
                EXTRACT_AND_COPY(short)
            break;

            case HDS_UWORD:
                EXTRACT_AND_COPY(unsigned short)
            break;

            case HDS_BYTE:
                EXTRACT_AND_COPY(char)
            break;

            case HDS_UBYTE:
                EXTRACT_AND_COPY(unsigned char)
            break;
        }
    }
#undef EXTRACT_AND_COPY
}

/**
 *  Name:
 *     gaiaArraySpectrumFromCube
 *
 *  Purpose:
 *     Given an array of 3 significant dimensions, in a supported data type,
 *     extract a 1D spectral section and return the data in that section. The
 *     dataType should be one of the enumerations HDS_ defined in gaiaArray.h
 *     (these correspond to the HDS data types).
 *
 *  Arguments:
 *     inPtr
 *         Pointer to the cube.
 *     type
 *         The data type (HDS_?).
 *     dims[3]
 *         The dimensions of the cube.
 *     axis
 *         The axis that will be extracted. One of 0, 1, 2. Extracting from
 *         the first axis is fastest.
 *     index1
 *     index2
 *         The indices of the spectrum to extract (these are along the two
 *         axes which are not "axis").
 *     cnfmalloc
 *         Whether to use cnfMalloc to allocate the image data. Otherwise
 *         malloc will be used.
 *     outPtr
 *         a pointer to a pointer that will point at the extracted spectrum on
 *         exit. This memory is allocated using malloc or cnfMalloc as
 *         determined by the final argument. Freeing it is the responsibility
 *         of the caller.
 *     nel 
 *         the number of elements extracted
 */
void gaiaArraySpectrumFromCube( void *inPtr, char type, int dims[3],
                                int axis, int index1, int index2,
                                int cnfmalloc, void **outPtr, int *nel )
{
    if ( axis == 0 ) {

        /* If we're extracting from the first dimension then this is just a
         * memcpy. */
        char *ptr;
        int strides[3];
        size_t length;
        size_t offset;

        *nel = (size_t) dims[axis];
        length = *nel * gaiaArraySizeOf( type );

        if ( cnfmalloc == 1 ) {
            *outPtr = cnfMalloc( length );
        }
        else {
            *outPtr = malloc( length );
        }

        /* Get the offset into cube of first pixel */
        gaiaArrayGetStrides( 3, dims, strides );
        offset = (size_t) strides[1] * index1 + (size_t) strides[2] * index2;
        ptr = ((char *) inPtr) + offset;

        /* And copy the memory */
        memcpy( *outPtr, ptr, length );
    }
    else {

        /* Noncontiguous memory, so need to pick it out pixel by pixel */
        int axis1;
        int axis2;
        int i;
        int indices[3];
        int j;
        int k;
        int l;
        int offset;
        int strides[3];
        size_t length;

        /* Get the strides for stepping around dimensions */
        gaiaArrayGetStrides( 3, dims, strides );

        /* Set up indices to select the spectrum */
        indices[0] = index1;
        if ( axis == 1 ) {
            indices[1] = 0;
            indices[2] = index2;
        }
        else {
            indices[1] = index2;
            indices[2] = 0;
        }

        /* Allocate the memory */
        *nel = (size_t) dims[axis];
        length = *nel * gaiaArraySizeOf( type );

        if ( cnfmalloc == 1 ) {
            *outPtr = cnfMalloc( length );
        }
        else {
            *outPtr = malloc( length );
        }

        /* Copy the spectrum, use type switch to keep pointer arithmetic
         * simple. Use macro to define repeated code. */
#define EXTRACT_AND_COPY(type)                  \
{                                               \
    type *fromPtr = (type *) inPtr;             \
    type *toPtr = (type *) *outPtr;             \
    for ( i = 0; i < *nel; i++ ) {                \
        offset = 0;                             \
        indices[axis] = i;                      \
        for ( j = 0; j < 3; j++ ) {             \
            offset += strides[j] * indices[j];  \
        }                                       \
        toPtr[i] = fromPtr[offset];             \
    }                                           \
}
        switch ( type )
        {
            case HDS_DOUBLE:
                EXTRACT_AND_COPY(double)
            break;
            case HDS_REAL:
                EXTRACT_AND_COPY(float)
            break;
            case HDS_INTEGER:
                EXTRACT_AND_COPY(int)
            break;
            case HDS_WORD:
                EXTRACT_AND_COPY(short)
            break;
            case HDS_UWORD:
                EXTRACT_AND_COPY(unsigned short)
            break;
            case HDS_BYTE:
                EXTRACT_AND_COPY(char)
            break;
            case HDS_UBYTE:
                EXTRACT_AND_COPY(unsigned char)
            break;
        }
    }
#undef EXTRACT_AND_COPY
}

/**
 * Return a set of column major (Fortran/FITS/NDF) order strides for
 * stepping around a vectorised array of the given dimensionality
 *
 * Once returned you can access the array element data(i,j,k) element, as
 * in the following code segment:
 *
 *    int indices[3];
 *    indices[0] = i;
 *    indices[1] = j;
 *    indices[2] = k;
 *    int offset = 0;
 *    for ( int l = 0; l < 3; l++ ) {
 *       offset += strides[l] * indices[l];
 *    }
 *    value = data[offset];
 */
void gaiaArrayGetStrides( int ndims, int dims[], int strides[] )
{
    int i;
    int count = 1;
    for ( i = 0; i < ndims; i++ ) {
        strides[i] = count;
        count *= dims[i];
    }
}
