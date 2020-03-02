! Module   : core_linalg
! Purpose  : interfaces to LAPACK and BLAS routines

$include 'core.inc'

module core_linalg

  ! Uses

  use core_kinds

  ! No implicit typing

  implicit none

  ! Interfaces

  ! LAPACK

  interface XGTSV
     subroutine SGTSV (N, NRHS, DL, D, DU, B, LDB, INFO)
       use core_kinds
       integer, intent(in) :: NRHS, N, LDB
       integer, intent(out) :: INFO
       real(SP), intent(inout) :: DL(*), D(*), DU(*), B(LDB,*)
     end subroutine SGTSV
     subroutine DGTSV (N, NRHS, DL, D, DU, B, LDB, INFO)
       use core_kinds
       integer, intent(in) :: NRHS, N, LDB
       integer, intent(out) :: INFO
       real(DP), intent(inout) :: DL(*), D(*), DU(*), B(LDB,*)
     end subroutine DGTSV
     subroutine CGTSV (N, NRHS, DL, D, DU, B, LDB, INFO)
       use core_kinds
       integer, intent(in) :: NRHS, N, LDB
       integer, intent(out) :: INFO
       complex(SP), intent(inout) :: DL(*), D(*), DU(*), B(LDB,*)
     end subroutine CGTSV
     subroutine ZGTSV (N, NRHS, DL, D, DU, B, LDB, INFO)
       use core_kinds
       integer, intent(in) :: NRHS, N, LDB
       integer, intent(out) :: INFO
       complex(DP), intent(inout) :: DL(*), D(*), DU(*), B(LDB,*)
     end subroutine ZGTSV
  end interface XGTSV

  interface XGETRF
     subroutine SGETRF (M, N, A, LDA, PIV, INFO)
       use core_kinds
       integer, intent(in) :: LDA, M, N
       integer, intent(out) :: INFO
       integer, intent(out) :: PIV( * )
       real(SP), intent(inout) :: A( LDA, * )
     end subroutine SGETRF
     subroutine DGETRF (M, N, A, LDA, PIV, INFO)
       use core_kinds
       integer, intent(in) :: LDA, M, N
       integer, intent(out) :: INFO
       integer, intent(out) :: PIV( * )
       real(DP), intent(inout) :: A( LDA, * )
     end subroutine DGETRF
     subroutine CGETRF (M, N, A, LDA, PIV, INFO)
       use core_kinds
       integer, intent(in) :: LDA, M, N
       integer, intent(out) :: INFO
       integer, intent(out) :: PIV( * )
       complex(SP), intent(inout) :: A( LDA, * )
     end subroutine CGETRF
     subroutine ZGETRF (M, N, A, LDA, PIV, INFO)
       use core_kinds
       integer, intent(in) :: LDA, M, N
       integer, intent(out) :: INFO
       integer, intent(out) :: PIV( * )
       complex(DP), intent(inout) :: A( LDA, * )
     end subroutine ZGETRF
  end interface XGETRF

  interface XGESV
     subroutine SGESV (N, NRHS, A, LDA, PIV, B, LDB, INFO)
       use core_kinds
       integer, intent(in) :: LDA, LDB, NRHS, N
       integer, intent(out) :: INFO
       integer, intent(out) :: PIV(*)
       real(SP), intent(inout) :: A(LDA,*), B(LDB,*)
     end subroutine SGESV
     subroutine DGESV (N, NRHS, A, LDA, PIV, B, LDB, INFO)
       use core_kinds
       integer, intent(in) :: LDA, LDB, NRHS, N
       integer, intent(out) :: INFO
       integer, intent(out) :: PIV(*)
       real(DP), intent(inout) :: A(LDA,*), B(LDB,*)
     end subroutine DGESV
     subroutine CGESV (N, NRHS, A, LDA, PIV, B, LDB, INFO)
       use core_kinds
       integer, intent(in) :: LDA, LDB, NRHS, N
       integer, intent(out) :: INFO
       integer, intent(out) :: PIV(*)
       complex(SP), intent(inout) :: A(LDA,*), B(LDB,*)
     end subroutine CGESV
     subroutine ZGESV (N, NRHS, A, LDA, PIV, B, LDB, INFO)
       use core_kinds
       integer, intent(in) :: LDA, LDB, NRHS, N
       integer, intent(out) :: INFO
       integer, intent(out) :: PIV(*)
       complex(DP), intent(inout) :: A(LDA,*), B(LDB,*)
     end subroutine ZGESV
  end interface XGESV

  interface XGEEV
     subroutine SGEEV (JOBVL, JOBVR, N, A, LDA, WR, WI, VL, LDVL, VR, LDVR, WORK, LWORK, INFO)
       use core_kinds
       character(1), intent(in) :: JOBVL, JOBVR
       integer, intent(in) :: N, LDA, LDVL, LDVR, LWORK
       integer, intent(out) :: INFO
       real(SP), intent(inout) :: A(LDA,*)
       real(SP), intent(out) :: VL(LDVL,*), VR(LDVR,*), WR(*), WI(*), WORK(*)
     end subroutine SGEEV
     subroutine DGEEV (JOBVL, JOBVR, N, A, LDA, WR, WI, VL, LDVL, VR, LDVR, WORK, LWORK, INFO)
       use core_kinds
       character(1), intent(in) :: JOBVL, JOBVR
       integer, intent(in) :: N, LDA, LDVL, LDVR, LWORK
       integer, intent(out) :: INFO
       real(DP), intent(inout) :: A(LDA,*)
       real(DP), intent(out) :: VL(LDVL,*), VR(LDVR,*), WR(*), WI(*), WORK(*)
     end subroutine DGEEV
     subroutine CGEEV (JOBVL, JOBVR, N, A, LDA, W, VL, LDVL, VR, LDVR, WORK, LWORK, RWORK, INFO )
       use core_kinds
       character(1), intent(in) :: JOBVL, JOBVR
       integer, intent(in) :: N, LDA, LDVL, LDVR, LWORK
       integer, intent(out) :: INFO
       real(SP), intent(out) :: RWORK(*)
       complex(SP), intent(inout) :: A(LDA,*)
       complex(SP), intent(out) :: VL(LDVL,*), VR(LDVR,*), W(*), WORK(*)
     end subroutine CGEEV
     subroutine ZGEEV (JOBVL, JOBVR, N, A, LDA, W, VL, LDVL, VR, LDVR, WORK, LWORK, RWORK, INFO)
       use core_kinds
       character(1), intent(in) :: JOBVL, JOBVR
       integer, intent(in) :: N, LDA, LDVL, LDVR, LWORK
       integer, intent(out) :: INFO
       real(DP), intent(out) :: RWORK(*)
       complex(DP), intent(inout) :: A(LDA,*)
       complex(DP), intent(out) :: VL(LDVL,*), VR(LDVR,*), W(*), WORK(*)
     end subroutine ZGEEV
  end interface XGEEV

  interface XGEEVX
     subroutine SGEEVX (BALANC, JOBVL, JOBVR, SENSE, N, A, LDA, WR, WI, VL, LDVL, VR, LDVR, ILO, IHI, SCALE, &
                        ABNRM, RCONDE, RCONDV, WORK, LWORK, IWORK, INFO)
       use core_kinds
       character(1), intent(in) :: BALANC, JOBVL, JOBVR, SENSE
       integer, intent(in) :: N, LDA, LDVL, LDVR, LWORK
       integer, intent(out) :: INFO, ILO, IHI, IWORK(*)
       real(SP), intent(out) :: ABNRM
       real(SP), intent(out) :: SCALE(*), RCONDE(*), RCONDV(*)
       real(SP), intent(inout) :: A(LDA,*)
       real(SP), intent(out) :: VL(LDVL,*), VR(LDVR,*), WR(*), WI(*), WORK(*)
     end subroutine SGEEVX
     subroutine DGEEVX (BALANC, JOBVL, JOBVR, SENSE, N, A, LDA, WR, WI, VL, LDVL, VR, LDVR, ILO, IHI, SCALE, &
                        ABNRM, RCONDE, RCONDV, WORK, LWORK, IWORK, INFO)
       use core_kinds
       character(1), intent(in) :: BALANC, JOBVL, JOBVR, SENSE
       integer, intent(in) :: N, LDA, LDVL, LDVR, LWORK
       integer, intent(out) :: INFO, ILO, IHI, IWORK(*)
       real(DP), intent(out) :: ABNRM
       real(DP), intent(out) :: SCALE(*), RCONDE(*), RCONDV(*)
       real(DP), intent(inout) :: A(LDA,*)
       real(DP), intent(out) :: VL(LDVL,*), VR(LDVR,*), WR(*), WI(*), WORK(*)
     end subroutine DGEEVX
     subroutine CGEEVX (BALANC, JOBVL, JOBVR, SENSE, N, A, LDA, W, VL, LDVL, VR, LDVR, ILO, IHI, SCALE, ABNRM, &
                        RCONDE, RCONDV, WORK, LWORK, RWORK, INFO )
       use core_kinds
       character(1), intent(in) :: BALANC, JOBVL, JOBVR, SENSE
       integer, intent(in) :: N, LDA, LDVL, LDVR, LWORK
       integer, intent(out) :: INFO, ILO, IHI
       real(SP), intent(out) :: ABNRM
       real(SP), intent(out) :: SCALE(*), RCONDE(*), RCONDV(*), RWORK(*)
       complex(WP), intent(inout) :: A(LDA,*)
       complex(WP), intent(out) :: VL(LDVL,*), VR(LDVR,*), W(*), WORK(*)
     end subroutine CGEEVX
     subroutine ZGEEVX (BALANC, JOBVL, JOBVR, SENSE, N, A, LDA, W, VL, LDVL, VR, LDVR, ILO, IHI, SCALE, ABNRM, &
                        RCONDE, RCONDV, WORK, LWORK, RWORK, INFO)
       use core_kinds
       character(1), intent(in) :: BALANC, JOBVL, JOBVR, SENSE
       integer, intent(in) :: N, LDA, LDVL, LDVR, LWORK
       integer, intent(out) :: INFO, ILO, IHI
       real(DP), intent(out) :: ABNRM
       real(DP), intent(out) :: SCALE(*), RCONDE(*), RCONDV(*), RWORK(*)
       complex(DP), intent(inout) :: A(LDA,*)
       complex(DP), intent(out) :: VL(LDVL,*), VR(LDVR,*), W(*), WORK(*)
     end subroutine ZGEEVX
  end interface XGEEVX

  interface XGESVD
     subroutine SGESVD (JOBU, JOBVT, M, N, A, LDA, S, U, LDU, VT, LDVT, WORK, LWORK, INFO)
       use core_kinds
       character(1), intent(in) :: JOBU, JOBVT
       integer, intent(in) :: M, N, LDA, LDU, LDVT, LWORK
       integer, intent(out) :: INFO
       real(SP), intent(out) :: S(*)
       real(SP), intent(inout) :: A(LDA,*)
       real(SP), intent(out) :: U(LDU,*), VT(LDVT,*), WORK(*)
     end subroutine SGESVD
     subroutine DGESVD (JOBU, JOBVT, M, N, A, LDA, S, U, LDU, VT, LDVT, WORK, LWORK, INFO)
       use core_kinds
       character(1), intent(in) :: JOBU, JOBVT
       integer, intent(in) :: M, N, LDA, LDU, LDVT, LWORK
       integer, intent(out) :: INFO
       real(DP), intent(out) :: S(*)
       real(DP), intent(inout) :: A(LDA,*)
       real(DP), intent(out) :: U(LDU,*), VT(LDVT,*), WORK(*)
     end subroutine DGESVD
     subroutine CGESVD (JOBU, JOBVT, M, N, A, LDA, S, U, LDU, VT, LDVT, WORK, LWORK, RWORK, INFO)
       use core_kinds
       character(1), intent(in) :: JOBU, JOBVT
       integer, intent(in) :: M, N, LDA, LDU, LDVT, LWORK
       integer, intent(out) :: INFO
       real(SP), intent(out) :: S(*), RWORK(*)
       complex(SP), intent(inout) :: A(LDA,*)
       complex(SP), intent(out) :: U(LDU,*), VT(LDVT,*), WORK(*)
     end subroutine CGESVD
     subroutine ZGESVD (JOBU, JOBVT, M, N, A, LDA, S, U, LDU, VT, LDVT, WORK, LWORK, RWORK, INFO)
       use core_kinds
       character(1), intent(in) :: JOBU, JOBVT
       integer, intent(in) :: M, N, LDA, LDU, LDVT, LWORK
       integer, intent(out) :: INFO
       real(DP), intent(out) :: S(*), RWORK(*)
       complex(DP), intent(inout) :: A(LDA,*)
       complex(DP), intent(out) :: U(LDU,*), VT(LDVT,*), WORK(*)
     end subroutine ZGESVD
  end interface XGESVD
  
  interface XSTEVR
     subroutine SSTEVR (JOBZ, RANGE, N, D, E, VL, VU, IL, IU, ABSTOL, &
                        M, W, Z, LDZ, ISUPPZ, WORK, LWORK, IWORK,     &
                        LIWORK, INFO)
       use core_kinds
       CHARACTER(1), intent(in) :: JOBZ, RANGE
       integer, intent(in) :: N, IL, IU, LDZ,  LWORK, LIWORK
       integer, intent(out) :: M
       integer, intent(out), target :: ISUPPZ(*)
       real(SP), intent(in) :: ABSTOL, VL, VU
       integer, intent(out) ::  IWORK(*)
       integer, intent(out) :: INFO
       real(SP), intent(inout) :: D(*), E(*)
       real(SP), intent(out) :: WORK(*), W(*)
       real(SP), intent(out), target :: Z(LDZ,*)
     end subroutine SSTEVR
     subroutine DSTEVR (JOBZ, RANGE, N, D, E, VL, VU, IL, IU, ABSTOL, &
                        M, W, Z, LDZ, ISUPPZ, WORK, LWORK, IWORK,     &
                        LIWORK, INFO)
       use core_kinds
       character(1), intent(in) :: JOBZ, RANGE
       integer, intent(in) :: N, IL, IU, LDZ,  LWORK, LIWORK
       integer, intent(out) :: M
       integer, intent(out), target :: ISUPPZ(*)
       real(DP), intent(in) :: ABSTOL, VL, VU
       integer, intent(out) ::  IWORK(*)
       integer, intent(out) :: INFO
       real(DP), intent(inout) :: D(*), E(*)
       real(DP), intent(out) :: WORK(*), W(*)
       real(DP), intent(out), target :: Z(LDZ,*)
     end subroutine DSTEVR
  end interface XSTEVR

  interface XLAMCH
     module procedure xlamch_r_sp_
     module procedure xlamch_r_dp_
  end interface XLAMCH

  ! Access specifiers

  private

  public :: XGTSV
  public :: XGETRF
  public :: XGESV
  public :: XGEEV
  public :: XGEEVX
  public :: XGESVD
  public :: XSTEVR
  public :: XLAMCH

contains

  $define $XLAMCH $sub

  $local $INFIX $1
  $local $TYPE $2
  $local $PREFIX $3

  function xlamch_${INFIX}_ (x, cmach)

    $TYPE, intent(in)        :: x
    character(*), intent(in) :: cmach
    $TYPE                    :: xlamch_${INFIX}_

    $TYPE, external :: ${PREFIX}LAMCH

    xlamch_${INFIX}_ = ${PREFIX}LAMCH(cmach)

  end function xlamch_${INFIX}_

  $endsub

  $XLAMCH(r_sp,real(SP),S)
  $XLAMCH(r_dp,real(DP),D)

end module core_linalg
