package edu.hawaii.jach.gsd;

import java.nio.*;
import java.nio.channels.*;
import java.io.*;
import java.util.*; // Item mapping by name

/**
 *  Read GSD file from disk and map data array.
 *  Data are read from mapped file on demand when requesting the
 *  data from GSDItem object.
 *
 *  Note that Java is big-endian but GSD is written in little-endian
 *  (VAX) format.
 *
 * @author  Tim Jenness (JAC)
 * @version $Id$
 */

public class GSDObject {

    // Constants
    // Size of GSD numerical data types in bytes
    private static final int GSD__SZBYTE    = GSDVAXBytes.VAX__SZBYTE;
    private static final int GSD__SZLOGICAL = GSDVAXBytes.VAX__SZLOGICAL;
    private static final int GSD__SZWORD    = GSDVAXBytes.VAX__SZWORD;
    private static final int GSD__SZINTEGER = GSDVAXBytes.VAX__SZINTEGER;
    private static final int GSD__SZREAL    = GSDVAXBytes.VAX__SZREAL;
    private static final int GSD__SZDOUBLE  = GSDVAXBytes.VAX__SZDOUBLE;

    // These constants denote how much space is used for the different
    // types of strings and what the maximum number of dimensions are
    // allowed for array data. These values are required for the header read.
    private static final int GSD__SZLABEL   = 40;
    private static final int GSD__SZUNIT    = 10;
    private static final int GSD__SZNAME    = 15;
    private static final int GSD__MAXDIMS   = 5;

    private static final char[] GSD__TYPES = { 'B','L','W','I','R','D','C' };

    // The file data itself
    private RandomAccessFile fptr;
    private ByteBuffer contents;

    // Global meta data from the file
    // Should be marked as final but we can not do this
    // because the values are set in a submethod and not a constructor
    // even though that method is called from the constructor.
    private int maxitems;
    private int no_items;
    private String label;
    private float version;
    private final String filename;
    private int start_data;
    private int end_data;
    private int size;

    // Item information plus lookup table
    private GSDItem items[];
    private Map itemmap;
    
    // Constructor just takes a file
    public GSDObject( String filename ) throws GSDException, 
	FileNotFoundException, IOException {

	// Need to open the file
	this.fptr = new RandomAccessFile( filename, "r" );

	// Store filename
	this.filename = filename;

	// First read the file header
	this.readFileDesc();

	// Then read the Item descriptor information
	this.readItemDesc();

	// Now map the data array and close the file
	this.mapData();

	// Now associate correct dimension information with each
	// array item (since they are specified by scalar items)
	this.fillDimItems();

	// and populate the look up table for fast by-name access
	this.fillItemMap();

    }

    //  General accessor methods
   /**
     * The GSD file label.
     */
    public String getLabel() {
        return this.label;
    }

    /**
     * The number of items read from the file.
     */
    public int getNumItems() {
        return this.no_items;
    }

    /**
     * The version number of this GSD file
     */
    public float getFileVersion() {
        return this.version;
    }

    /**
     * The name of the GSD file
     */
    public String getFilename() {
        return this.filename;
    }

    /**
     * Retrieve all the items associated with this GSD file.
     * Note that the array returned by this method is indexed in the
     * normal manner (starting at zero) and that this differs from the
     * standard numbering of GSD items as used in the itemByNum() method.
     *
     * @return GSDItem[] array indexed from zero.
     */
    public GSDItem[] items() {
	// Make sure we return a copy of the array so that the contents
	// and ordering of the items associated with this object can
	// not be tweaked.
	return (GSDItem[])this.items.clone();
    }

   /**
     * Return item contents by GSD item name. Throws a GSDException
     * if the item named is not present. Item names are case insensitive.
     *
     * @param itemname Name of the requested item.
     * @return a GSDItem object with all the Item information
     */
    public GSDItem itemByName( String itemname ) throws GSDException {
	itemname = itemname.toUpperCase();
        GSDItem result = (GSDItem)this.itemmap.get( itemname );
	if (result == null) {
	    throw new GSDException("Item "+ itemname + 
				   " is not present in the file");
	}
        return result;
    }

    /**
     * Return item contents by GSD item number. Throws a GSDException
     * exception if the item is not present.
     *
     * @param itemno The item number (starting at 1, maximum value defined
     *               by getNumItems)
     * @return a GSDItem object with all the Item information
     */
    public GSDItem itemByNum( int itemno ) throws GSDException {
	if (itemno < 1 || itemno > this.getNumItems()) {
	    throw new GSDException("Requested item, " + itemno + 
				   ", is outside the file limits of 0 and " 
				   + this.getNumItems());
	}
        GSDItem result = this.items[itemno-1];
        return result;
    }

    /**
     * Returns a short summary of the object. The format of this string
     * is not specified but may include the file name and the number of
     * data items.
     */
    public String toString() {
	String datastring;
	try {
	    GSDItem maindata = this.itemByName( "C13DAT" );
	    datastring = " Data array size: " + maindata.size() + " elements";
	} catch ( GSDException e ) {
	    datastring = "No C13DAT";
	}
	String result = "GSD file: " + this.getFilename() +
	    " Number of items: " + this.getNumItems() +
	    datastring;
	return result;
    }


    /**
     * Dump the contents of the file as text to standard out
     * without special formatting. Equivalent to the gsdprint
     * command.
     */
    public void print() throws IOException, GSDException {
        System.out.println("-----------------------------------------------------");
	System.out.println(" G S D   P R I N T");
	System.out.println("-----------------------------------------------------");
        System.out.println("");
        System.out.println(" Filename       : "+ getFilename() );
        System.out.println(" GSD version    : "+ getFileVersion() );
        System.out.println(" Label          : "+ getLabel() );
        System.out.println(" Number of item : "+ getNumItems() );
        System.out.println("");
        System.out.println("");
        System.out.println("");
	System.out.println("Name            Unit            Type    Arr?    Value");	
	System.out.println("-----------------------------------------------------");

	// Upper limit for number of data values to print. Should
	// be an argument so that a command line option can be 
	// triggered.
	long maxsize = 1024;

	// Loop over each item. Draw a divider if we have just reached
        // an array item
        for (int i = 1; i<= getNumItems(); i++) {
            GSDItem item = itemByNum( i );

            // print a divider if we are an array item
            if (item.isArray()) {
		System.out.println("-----------------------------------------------------");
	    }

            item.dumpIt(maxsize);

        }
    }

    /* I N T E R N A L   I O   R O U T I N E S */

    private void readFileDesc () throws IOException, GSDException {
	// Read the first few bytes for the general file description

	/**
	   The GSD file descriptor is defined as follows:
	   [See also gsd1.h in struct file_descriptor]

	   float version;      GSD file format version for SPECX         
	   int   max_no_items;    Maximum number of items in file ?         
	   int   no_items;        Number of items in this file    ?         
	   int   str_data;        Start of data area in file - byte number  
	   int   end_data;        End of data area - byte number       
	   char  comment[40];
	   int size;

	*/

	// For efficiency reasons do a single read and then extract
	// the contents from the byte buffer
	int[] struct = {
	    GSD__SZREAL,     // version
	    GSD__SZINTEGER,  // max_no_items
	    GSD__SZINTEGER,  // no_items
	    GSD__SZINTEGER,  // str_data
	    GSD__SZINTEGER,  // end_data
	    GSD__SZLABEL,    // comment[40]
	    GSD__SZINTEGER   // size
	};

	int szstruct = 0;
	for (int i=0; i< struct.length; i++) {
	    szstruct += struct[i];
	}
	    
	// offset into byte buffer
	int offset = 0;

	// position in struct
	int i = 0;

	// Some bytes for the struct
	byte[] byteArray = new byte[szstruct];

	// Read the data
	int nread = this.fptr.read(byteArray,0, szstruct);
	// System.out.println("Read " + nread + " bytes");
	if ( nread != szstruct ) {
	    throw new GSDException("Error reading main header!");
	}

	// Versions
	this.version = GSDVAXBytes.tofloat( byteArray, offset );

	offset += struct[i]; i++;
	this.maxitems = GSDVAXBytes.toint( byteArray, offset);

	offset += struct[i]; i++;
	this.no_items = GSDVAXBytes.toint( byteArray, offset );

	offset += struct[i]; i++;
	this.start_data = GSDVAXBytes.toint( byteArray, offset );

	offset += struct[i]; i++;
	this.end_data = GSDVAXBytes.toint( byteArray, offset );

	offset += struct[i]; i++;
	this.label = GSDVAXBytes.tostring( byteArray, offset, GSD__SZLABEL );

	offset += struct[i]; i++;
	this.size = GSDVAXBytes.toint( byteArray, offset );

	//System.out.println("Read: " + this.no_items +
	//		   " and "  + this.maxitems +
	//		   " and " + this.version +
	//		   " and " + this.label + ";"
	//		   );
	//System.out.println( "Start pos: " + this.start_data +
	//		    " End pos: " + this.end_data +
	//		    " Size: " + this.size);

    };


    private void readItemDesc () throws IOException, GSDException {

	// For each of the no_items items in the file the next
	// block of the file contains the information associated
	// with each item but not the data itself
	// [which is to be mapped later]
	//
	/* The struct is implemented as follows:
	   char  array;
	   char  name[15];
	   short namelen;
	   char  unit[10];
	   short unitlen;
	   short data_type;
	   int   location;
	   int   length;
	   int   no_dims;
	   int   dimnumbers[5];
	   
	   But we assume there are no extra bytes padding the file
	   for now (a safe assumption since it is unlikely that
	   the VAX will decide to change format on us)
	*/

	// For efficiency reasons do a single read of the item block 
	// and then extract the contents from the byte buffer
	int[] struct = {
	    GSD__SZLOGICAL, // array
	    GSD__SZNAME,    // name[15]
	    GSD__SZWORD,    // namelen
	    GSD__SZUNIT,    // unit[10]
	    GSD__SZWORD,    // unitlen
	    GSD__SZWORD,    // data_type
	    GSD__SZINTEGER, // location
	    GSD__SZINTEGER, // length
	    GSD__SZINTEGER, // no_dims
	    GSD__SZINTEGER*GSD__MAXDIMS // dimnumbers[5]
	};

	int szstruct = 0;
	for (int i=0; i< struct.length; i++) {
	    szstruct += struct[i];
	}

	// Read in a byte array for all the item descriptions
	// There should not be a massive overhead to this since the
	// number of items is always finite (and for JCMT no more than
	// 200 items)
	byte[] byteArray = new byte[ szstruct * this.no_items ];

	// Somewhere to put the items contents
	items = new GSDItem[this.no_items];

	// Read the buffer in one ago. I assume this is more efficient
	// than using little chunks
	//System.out.println("Attempting to read " + 
	//		   (szstruct*this.no_items) + " bytes");
	int nread = this.fptr.read( byteArray, 0, szstruct * this.no_items );
	if (nread != (szstruct * this.no_items) ) {
	    throw new GSDException("Error reading Item header!");
	}
	//System.out.println("Read " + nread + " bytes from item header");

	// Loop over each scalar item in turn. We will do the array items
	// with a second pass
	for (int i = 0; i< this.no_items; i++ ) {

	    // recalculate global offset on the basis of index rather than
	    // assuming we have started at the beginning
	    int offset = (szstruct * i);

	    // index into current struct
	    int j = 0;

	    // isArray item?
	    boolean isArray = GSDVAXBytes.tobool( byteArray, offset );

	    // Item name and then its length
	    offset += struct[j]; j++;
	    String itemname = GSDVAXBytes.tostring( byteArray, offset,
						    GSD__SZNAME );

	    offset += struct[j]; j++;
	    short namelen = GSDVAXBytes.toshort( byteArray, offset );

	    // Extract the substring of the right length
	    itemname = itemname.substring(0,namelen);

	    // Data units [10 characters] plus length
	    offset += struct[j]; j++;
	    String itemunit = GSDVAXBytes.tostring( byteArray, offset,
						    GSD__SZUNIT );

	    offset += struct[j]; j++;
	    short unitlen = GSDVAXBytes.toshort( byteArray, offset );

	    // Must trim the string
	    itemunit = itemunit.substring(0,unitlen);

	    // Data type
	    offset += struct[j]; j++;
	    short type = GSDVAXBytes.toshort( byteArray, offset );

	    // curritem.type( GSD__TYPES[type-1] );
	    //System.out.println("Data type = " + curritem.type() );

	    // Location of this item in the data array
	    // corrected for the start position of the GSD data segment
	    offset += struct[j]; j++;
	    int start_byte = GSDVAXBytes.toint( byteArray, offset ) -
		this.start_data;

	    // Number of bytes in data array to read
	    offset += struct[j]; j++;
	    int nbytes =  GSDVAXBytes.toint( byteArray, offset );
	    
	    // Number of dimensions if array
	    // Some dimensions can be negative (!) -1
	    // Set those to 0 assuming we are scalar
	    offset += struct[j]; j++;
	    int ndims = GSDVAXBytes.toint( byteArray, offset );

	    //System.out.println("Location: " +  curritem.start_byte() +
	    //		       " Length = "  + curritem.nbytes()  +
	    //		       " bytes, Ndims  = " + curritem.ndims() 
	    //		       );

	    // This is an array of item numbers corresponding to each
	    // dimension in the scalar part of the header. If one of the
	    // dimensions says 83 that means the dimension is specified
	    // by the contents of scalar item 83.
	    offset += struct[j];
	    int[] dimnumbers = GSDVAXBytes.tointArray(byteArray, 
						      offset, GSD__MAXDIMS);

	    // and create the actual object
	    GSDItem curritem = new GSDItem( i+1, start_byte, nbytes,
					    ndims, itemname, itemunit, 
					    GSD__TYPES[type-1],
					    dimnumbers );

	    // and place the item in context
	    items[i] = curritem;

	}

    }

    // Attach dimension information to array data
    private void fillDimItems() throws GSDException, IOException {

	// Attach the dimensional information from dimnumbers
	for (int i = 0; i< this.no_items; i++) {
	    GSDItem item = items[i];
	    if ( item.isArray() ) {
		// Only relevant for array items
		// Might want to think about simply storing
		// the items and then providing wrappers for
		// dimnames and dimunits???
		int ndims = item.ndims();

		// Make the arrays the right size
		String[] dimunits = new String[ndims];
		String[] dimnames = new String[ndims];
		int[] dimensions = new int[ndims];

		int[] dimnumbers = item.dimnumbers();
		for (int j=0; j<ndims; j++) {
		    // The item number is one off from the index
		    GSDItem dimitem = items[ dimnumbers[j]-1 ];

		    dimunits[j] = dimitem.unit();
		    dimnames[j] = dimitem.name();
		    Integer dim = (Integer)dimitem.getData();
		    dimensions[j] = dim.intValue();
		}
		
		// And store
		item.dimunits( dimunits );
		item.dimnames( dimnames );
		item.dimensions( dimensions );
	    }
	}

    }

    private void fillItemMap() {
	// use HashMap for now
	itemmap = new HashMap( getNumItems() );

	// Now read in all the items
        for (int i = 0; i< getNumItems(); i++) {
            itemmap.put(items[i].name(), items[i]);
        }
    }


    // We always map the data segment even if we have a small
    // file. We may want to consider reading small files into a normal
    // ByteBuffer (the system will support this without any changes
    // to other places in the code).
    private void mapData() throws IOException {

	// Now need to get the channel
	FileChannel chan = fptr.getChannel();

	// And the mapped contents
	contents = chan.map( FileChannel.MapMode.READ_ONLY,
			     start_data,
			     end_data - start_data + 1);

	// And attach this to all the items so that they can
	// read the data themselves
	for (int i = 0; i< getNumItems(); i++) {
	    items[i].contents( contents );
	}

	// We can also "close" the file since we no longer need it
	fptr.close();
	fptr = null;

    }

}


