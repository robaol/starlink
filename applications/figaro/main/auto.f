      subroutine auto(status)
*+
* Name:
*    AUTO

* Invocation:
*    CALL AUTO(STATUS)
* Purpose:
*  Determine locations of comb spectra over frame.

* Description:
*   Subroutine to calculate automatically (except for initial setting of
*  windows) centres of data on continua lines and to display the results
*  on a graphics device.

* Arguments:
*    STATUS = INTEGER (Given and returned)
*        Error status
* History:
*  Altered TNW 11/11/88 to no longer erase graphics screen at end of
*  routine-unlikely to be run interactively anyway.
*  Now uses DSA_AXIS_RANGE TNW 25/1/91
*  Workspace changes, TNW 11/2/91
*
      implicit none
      include 'SAE_PAR'
      include 'arc_dims'
*- ---------------------------------------------------------------------
      integer status
*  Local
*
      integer nwindow
      integer xstart,xend
      integer nbls,ptr1,ptr2,slot
      real value,value1
      include 'DYNAMIC_MEMORY'
      include 'PRM_PAR'
*
*
      call par_rdval('xblock',1.0,real(wavdim),20.0,'Channels',value)

      nwindow = nint(value)
      nbls = wavdim/nwindow

      call dsa_axis_range('data',1,' ',.false.,value,value1,xstart,xend,
     :      status)

      call getwork(line_count*2,'float',ptr1,slot,status)
      if(status.ne.SAI__OK) return
      ptr2 = ptr1 + line_count*VAL__NBR
      call comb_window(dynamic_mem(d_xptr),dynamic_mem(d_vsptr),nbls,
     :      nwindow,%VAL(d_tlptr),%VAL(d_trptr),xstart,
     :      xend,dynamic_mem(ptr1),dynamic_mem(ptr2))
      call dsa_free_workspace(slot,status)
      end
