! Module   : gyre_evol_model
! Purpose  : stellar evolutionary model
!
! Copyright 2013 Rich Townsend
!
! This file is part of GYRE. GYRE is free software: you can
! redistribute it and/or modify it under the terms of the GNU General
! Public License as published by the Free Software Foundation, version 3.
!
! GYRE is distributed in the hope that it will be useful, but WITHOUT
! ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
! or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
! License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

$include 'core.inc'
$include 'core_parallel.inc'

module gyre_evol_model

  ! Uses

  use core_kinds
  use core_parallel
  use core_spline
  use core_table

  use gyre_constants
  use gyre_model
  use gyre_cocache

  use ISO_FORTRAN_ENV

  ! No implicit typing

  implicit none

  ! Parameters

  logical, parameter :: IMPLICIT_U = .FALSE.
  logical, parameter :: IMPLICIT_GAMMA_1 = .FALSE.

  integer, parameter :: J_M = 1
  integer, parameter :: J_P = 2
  integer, parameter :: J_RHO = 3
  integer, parameter :: J_T = 4
  integer, parameter :: J_V = 5
  integer, parameter :: J_AS = 6
  integer, parameter :: J_U = 7
  integer, parameter :: J_C_1 = 8
  integer, parameter :: J_GAMMA_1 = 9
  integer, parameter :: J_NABLA_AD = 10
  integer, parameter :: J_DELTA = 11
  integer, parameter :: J_OMEGA_ROT = 12
  integer, parameter :: J_NABLA = 13
  integer, parameter :: J_C_RAD = 14
  integer, parameter :: J_DC_RAD = 15
  integer, parameter :: J_C_THM = 16
  integer, parameter :: J_C_DIF = 17
  integer, parameter :: J_C_EPS_AD = 18
  integer, parameter :: J_C_EPS_S = 19
  integer, parameter :: J_KAPPA_AD = 20
  integer, parameter :: J_KAPPA_S = 21
  integer, parameter :: J_TAU_THM = 22

  integer, parameter :: N_J = 22

  ! Derived-type definitions

  $define $PROC_DECL $sub
    $local $NAME $1
    procedure :: ${NAME}_1_
    procedure :: ${NAME}_v_
  $endsub

  $define $PROC_DECL_GEN $sub
    $local $NAME $1
    procedure       :: ${NAME}_1_
    procedure       :: ${NAME}_v_
    generic, public :: ${NAME} => ${NAME}_1_, ${NAME}_v_
  $endsub

  type, extends (model_t) :: evol_model_t
     private
     type(spline_t), allocatable :: sp(:)
     logical, allocatable        :: sp_def(:)
     type(cocache_t), pointer    :: cc => null()
     real(WP), public            :: M_star
     real(WP), public            :: R_star
     real(WP), public            :: L_star
     real(WP)                    :: p_c
     real(WP)                    :: rho_c
   contains
     private
     procedure         :: set_sp_
     $PROC_DECL_GEN(m)
     $PROC_DECL_GEN(p)
     $PROC_DECL_GEN(rho)
     $PROC_DECL_GEN(T)
     $PROC_DECL(V)
     $PROC_DECL(As)
     $PROC_DECL(U)
     $PROC_DECL(c_1)
     $PROC_DECL(Gamma_1)
     $PROC_DECL(nabla_ad)
     $PROC_DECL(delta)
     $PROC_DECL(Omega_rot)
     $PROC_DECL(c_rad)
     $PROC_DECL(dc_rad)
     $PROC_DECL(c_thm)
     $PROC_DECL(c_dif)
     $PROC_DECL(c_eps_ad)
     $PROC_DECL(c_eps_S)
     $PROC_DECL(nabla)
     $PROC_DECL(kappa_ad)
     $PROC_DECL(kappa_S)
     $PROC_DECL(tau_thm)
     procedure, public :: pi_c => pi_c_
     procedure, public :: is_zero => is_zero_
     procedure, public :: attach_cache => attach_cache_
     procedure, public :: detach_cache => detach_cache_
     procedure, public :: fill_cache => fill_cache_
!     procedure, public :: regularize => regularize_
  end type evol_model_t
 
  ! Interfaces

  interface evol_model_t
     module procedure evol_model_t_
     module procedure evol_model_t_mech_
     module procedure evol_model_t_mech_coeffs_
     module procedure evol_model_t_full_
  end interface evol_model_t

  $if ($MPI)
  interface bcast
     module procedure bcast_
  end interface bcast
  $endif

  ! Access specifiers

  private

  public :: evol_model_t
  $if ($MPI)
  public :: bcast
  $endif

  ! Procedures

contains

  function evol_model_t_ () result (ml)

    type(evol_model_t) :: ml

    ! Construct the evol_model_t

    allocate(ml%sp(N_J))

    allocate(ml%sp_def(N_J))
    ml%sp_def = .FALSE.

    ml%cc => null()

    ! Finish

    return

  end function evol_model_t_

!****

  recursive function evol_model_t_mech_ (M_star, R_star, L_star, r, m, p, rho, T, N2, &
                                        Gamma_1, nabla_ad, delta, Omega_rot, &
                                        deriv_type, regularize, add_center) result (ml)

    real(WP), intent(in)          :: M_star
    real(WP), intent(in)          :: R_star
    real(WP), intent(in)          :: L_star
    real(WP), intent(in)          :: r(:)
    real(WP), intent(in)          :: m(:)
    real(WP), intent(in)          :: p(:)
    real(WP), intent(in)          :: rho(:)
    real(WP), intent(in)          :: T(:)
    real(WP), intent(in)          :: N2(:)
    real(WP), intent(in)          :: Gamma_1(:)
    real(WP), intent(in)          :: nabla_ad(:)
    real(WP), intent(in)          :: delta(:)
    real(WP), intent(in)          :: Omega_rot(:)
    character(LEN=*), intent(in)  :: deriv_type
    logical, optional, intent(in) :: regularize
    logical, optional, intent(in) :: add_center
    type(evol_model_t)            :: ml

    logical  :: regularize_
    logical  :: add_center_
    integer  :: n
    real(WP) :: m_reg(SIZE(r))
    real(WP) :: p_reg(SIZE(r))
    real(WP) :: N2_reg(SIZE(r))
    real(WP) :: V(SIZE(r))
    real(WP) :: As(SIZE(r))
    real(WP) :: U(SIZE(r))
    real(WP) :: c_1(SIZE(r))
    real(WP) :: Omega_rot_(SIZE(r))
    real(WP) :: x(SIZE(r))

    $CHECK_BOUNDS(SIZE(m),SIZE(r))
    $CHECK_BOUNDS(SIZE(p),SIZE(r))
    $CHECK_BOUNDS(SIZE(rho),SIZE(r))
    $CHECK_BOUNDS(SIZE(T),SIZE(r))
    $CHECK_BOUNDS(SIZE(N2),SIZE(r))
    $CHECK_BOUNDS(SIZE(Gamma_1),SIZE(r))
    $CHECK_BOUNDS(SIZE(nabla_ad),SIZE(r))
    $CHECK_BOUNDS(SIZE(delta),SIZE(r))
    $CHECK_BOUNDS(SIZE(Omega_rot),SIZE(r))

    if (PRESENT(regularize)) then
       regularize_ = regularize
    else
       regularize_ = .FALSE.
    endif

    if(PRESENT(add_center)) then
       add_center_ = add_center
    else
       add_center_ = .FALSE.
    endif

    ! Construct the evol_model_t using the mechanical structure data

    ! See if we need a central point

    if (add_center_) then

       ! Add a central point and initialize using recursion

       ml = evol_model_t(M_star, R_star, L_star, [0._WP,r], [0._WP,m], &
                         prep_center_(r, p), prep_center_(r, rho), prep_center_(r, T), &
                         [0._WP,N2], prep_center_(r, Gamma_1), prep_center_(r, nabla_ad), prep_center_(r, delta), &
                         prep_center_(r, Omega_rot), deriv_type, regularize, .FALSE.)

    elseif (regularize_) then

       ! Regularize and initialize using recursion

       n = SIZE(r)

       call regularize_data_(r, m, p, rho, Gamma_1, N2, deriv_type, m_reg, p_reg, N2_reg)

       ml = evol_model_t(m_reg(n), R_star, L_star, r, m_reg, &
                         p_reg, rho, T, &
                         N2_reg, Gamma_1, nabla_ad, delta, &
                         Omega_rot, deriv_type, .FALSE., .FALSE.)

    else
       
       ! Perform basic validations
       
       n = SIZE(r)

       $ASSERT(r(1) == 0._WP,First grid point not at center)
       $ASSERT(m(1) == 0._WP,First grid point not at center)

       $ASSERT(ALL(r(2:) > r(:n-1)),Non-monotonic radius data)
       $ASSERT(ALL(m(2:) >= m(:n-1)),Non-monotonic mass data)

       ! Calculate coefficients

       where(r /= 0._WP)
          V = G_GRAVITY*m*rho/(p*r)
          As = r**3*N2/(G_GRAVITY*m)
          U = 4._WP*PI*rho*r**3/m
          c_1 = (r/R_star)**3/(m/M_star)
       elsewhere
          V = 0._WP
          As = 0._WP
          U = 3._WP
          c_1 = 3._WP*(M_star/R_star**3)/(4._WP*PI*rho)
       end where

       Omega_rot_ = SQRT(R_star**3/(G_GRAVITY*M_star))*Omega_rot

       x = r/R_star

       ! Initialize the model

       ml = evol_model_t()

       !$OMP PARALLEL SECTIONS
       !$OMP SECTION
       call ml%set_sp_(x, m, deriv_type, J_M)
       !$OMP SECTION
       call ml%set_sp_(x, p, deriv_type, J_P)
       !$OMP SECTION
       call ml%set_sp_(x, rho, deriv_type, J_RHO)
       !$OMP SECTION
       call ml%set_sp_(x, T, deriv_type, J_T)
       !$OMP SECTION
       call ml%set_sp_(x, V, deriv_type, J_V)
       !$OMP SECTION
       call ml%set_sp_(x, As, deriv_type, J_AS)
       !$OMP SECTION
       call ml%set_sp_(x, U, deriv_type, J_U)
       !$OMP SECTION
       call ml%set_sp_(x, c_1, deriv_type, J_C_1)
       !$OMP SECTION
       call ml%set_sp_(x, Gamma_1, deriv_type, J_GAMMA_1)
       !$OMP SECTION
       call ml%set_sp_(x, nabla_ad, deriv_type, J_NABLA_AD)
       !$OMP SECTION
       call ml%set_sp_(x, delta, deriv_type, J_DELTA)
       !$OMP SECTION
       call ml%set_sp_(x, Omega_rot_, deriv_type, J_OMEGA_ROT)
       !$OMP END PARALLEL SECTIONS

       ml%M_star = M_star
       ml%R_star = R_star
       ml%L_star = L_star

       ml%p_c = p(1)
       ml%rho_c = rho(1)

    endif

    ! Finish

    return

  end function evol_model_t_mech_

!****

  recursive function evol_model_t_mech_coeffs_ (M_star, R_star, L_star, x, &
                                                V, As, U, c_1, Gamma_1, &
                                                deriv_type, add_center) result (ml)

    real(WP), intent(in)          :: M_star
    real(WP), intent(in)          :: R_star
    real(WP), intent(in)          :: L_star
    real(WP), intent(in)          :: x(:)
    real(WP), intent(in)          :: V(:)
    real(WP), intent(in)          :: As(:)
    real(WP), intent(in)          :: U(:)
    real(WP), intent(in)          :: c_1(:)
    real(WP), intent(in)          :: Gamma_1(:)
    character(LEN=*), intent(in)  :: deriv_type
    logical, optional, intent(in) :: add_center
    type(evol_model_t)            :: ml

    logical  :: add_center_

    $CHECK_BOUNDS(SIZE(V),SIZE(x))
    $CHECK_BOUNDS(SIZE(As),SIZE(x))
    $CHECK_BOUNDS(SIZE(U),SIZE(x))
    $CHECK_BOUNDS(SIZE(c_1),SIZE(x))
    $CHECK_BOUNDS(SIZE(Gamma_1),SIZE(x))

    if(PRESENT(add_center)) then
       add_center_ = add_center
    else
       add_center_ = .FALSE.
    endif

    ! Construct the evol_model_t using the dimensionless coefficients

    ! See if we need a central point

    if(add_center_) then

       ! Add a central point and initialize using recursion
       
       ml = evol_model_t(M_star, R_star, L_star, &
                         [0._WP,x], [0._WP,V], [0._WP,As], [3._WP,U], &
                         prep_center_(x, c_1), prep_center_(x, Gamma_1), deriv_type, .FALSE.)

    else

       ! Initialize the model

       ml = evol_model_t()

       !$OMP PARALLEL SECTIONS
       !$OMP SECTION
       call ml%set_sp_(x, V, deriv_type, J_V)
       !$OMP SECTION
       call ml%set_sp_(x, As, deriv_type, J_AS)
       !$OMP SECTION
       call ml%set_sp_(x, U, deriv_type, J_U)
       !$OMP SECTION
       call ml%set_sp_(x, c_1, deriv_type, J_C_1)
       !$OMP SECTION
       call ml%set_sp_(x, Gamma_1, deriv_type, J_GAMMA_1)
       !$OMP SECTION
       call ml%set_sp_(x, SPREAD(0._WP, 1, SIZE(x)), deriv_type, J_OMEGA_ROT)
       !$OMP END PARALLEL SECTIONS

       ml%M_star = M_star
       ml%R_star = R_star
       ml%L_star = L_star

       ml%rho_c = 0._WP
       ml%p_c = 0._WP

    endif

    ! Finish

    return

  end function evol_model_t_mech_coeffs_

!****

  recursive function evol_model_t_full_ (M_star, R_star, L_star, r, m, p, rho, T, N2, &
                                         Gamma_1, nabla_ad, delta, Omega_rot, &
                                         nabla, kappa, kappa_rho, kappa_T, &
                                         epsilon, epsilon_rho, epsilon_T, &
                                         deriv_type, regularize, add_center) result (ml)

    real(WP), intent(in)          :: M_star
    real(WP), intent(in)          :: R_star
    real(WP), intent(in)          :: L_star
    real(WP), intent(in)          :: r(:)
    real(WP), intent(in)          :: m(:)
    real(WP), intent(in)          :: p(:)
    real(WP), intent(in)          :: rho(:)
    real(WP), intent(in)          :: T(:)
    real(WP), intent(in)          :: N2(:)
    real(WP), intent(in)          :: Gamma_1(:)
    real(WP), intent(in)          :: nabla_ad(:)
    real(WP), intent(in)          :: delta(:)
    real(WP), intent(in)          :: Omega_rot(:)
    real(WP), intent(in)          :: nabla(:)
    real(WP), intent(in)          :: kappa(:)
    real(WP), intent(in)          :: kappa_rho(:)
    real(WP), intent(in)          :: kappa_T(:)
    real(WP), intent(in)          :: epsilon(:)
    real(WP), intent(in)          :: epsilon_rho(:)
    real(WP), intent(in)          :: epsilon_T(:)
    character(LEN=*), intent(in)  :: deriv_type
    logical, optional, intent(in) :: regularize
    logical, optional, intent(in) :: add_center
    type(evol_model_t)            :: ml

    logical  :: regularize_
    logical  :: add_center_
    integer  :: n
    real(WP) :: m_reg(SIZE(r))
    real(WP) :: p_reg(SIZE(r))
    real(WP) :: N2_reg(SIZE(r))
    real(WP) :: x(SIZE(r))
    real(WP) :: V(SIZE(r))
    real(WP) :: V_x2(SIZE(r))
    real(WP) :: c_p(SIZE(r))
    real(WP) :: c_rad(SIZE(r))
    real(WP) :: c_thm(SIZE(r))
    real(WP) :: c_dif(SIZE(r))
    real(WP) :: kappa_ad(SIZE(r))
    real(WP) :: kappa_S(SIZE(r))
    real(WP) :: epsilon_ad(SIZE(r))
    real(WP) :: epsilon_S(SIZE(r))
    real(WP) :: c_eps_ad(SIZE(r))
    real(WP) :: c_eps_S(SIZE(r))
    real(WP) :: dtau_thm(SIZE(r))
    real(WP) :: tau_thm(SIZE(r))
    integer  :: i

    $CHECK_BOUNDS(SIZE(m),SIZE(r))
    $CHECK_BOUNDS(SIZE(p),SIZE(r))
    $CHECK_BOUNDS(SIZE(rho),SIZE(r))
    $CHECK_BOUNDS(SIZE(T),SIZE(r))
    $CHECK_BOUNDS(SIZE(N2),SIZE(r))
    $CHECK_BOUNDS(SIZE(Gamma_1),SIZE(r))
    $CHECK_BOUNDS(SIZE(nabla_ad),SIZE(r))
    $CHECK_BOUNDS(SIZE(delta),SIZE(r))
    $CHECK_BOUNDS(SIZE(nabla),SIZE(r))
    $CHECK_BOUNDS(SIZE(kappa),SIZE(r))
    $CHECK_BOUNDS(SIZE(kappa_T),SIZE(r))
    $CHECK_BOUNDS(SIZE(kappa_rho),SIZE(r))
    $CHECK_BOUNDS(SIZE(epsilon),SIZE(r))
    $CHECK_BOUNDS(SIZE(epsilon_T),SIZE(r))
    $CHECK_BOUNDS(SIZE(epsilon_rho),SIZE(r))
    $CHECK_BOUNDS(SIZE(Omega_rot),SIZE(r))

    if (PRESENT(regularize)) then
       regularize_ = regularize
    else
       regularize_ = .FALSE.
    endif

    if (PRESENT(add_center)) then
       add_center_ = add_center
    else
       add_center_ = .FALSE.
    endif

    ! Construct the evol_model using the full structure data

    if (add_center_) then

       ! Add a central point and initialize using recursion

       ml = evol_model_t(M_star, R_star, L_star, [0._WP,r], [0._WP,m], &
                         prep_center_(r, p), prep_center_(r, rho), prep_center_(r, T), [0._WP,N2], &
                         prep_center_(r, Gamma_1), prep_center_(r, nabla_ad), prep_center_(r, delta), prep_center_(r, Omega_rot), &
                         prep_center_(r, nabla), prep_center_(r, kappa), prep_center_(r, kappa_rho), prep_center_(r, kappa_T), &
                         prep_center_(r, epsilon), prep_center_(r, epsilon_rho), prep_center_(r, epsilon_T), &
                         deriv_type, regularize_, .FALSE.)

    elseif (regularize_) then

       ! Regularize and initialize using recursion

       n = SIZE(r)

       call regularize_data_(r, m, p, rho, Gamma_1, N2, deriv_type, m_reg, p_reg, N2_reg)

       ml = evol_model_t(m_reg(n), R_star, L_star, r, m_reg, &
                         p_reg, rho, T, N2_reg, &
                         Gamma_1, nabla_ad, delta, Omega_rot, &
                         nabla, kappa, kappa_rho, kappa_T, &
                         epsilon, epsilon_rho, epsilon_T, &
                         deriv_type, .FALSE., .FALSE.)

    else

       ! Perform basic validations
       
       n = SIZE(r)

       $ASSERT(r(1) == 0._WP,First grid point not at center)
       $ASSERT(m(1) == 0._WP,First grid point not at center)

       $ASSERT(ALL(r(2:) > r(:n-1)),Non-monotonic radius data)
       $ASSERT(ALL(m(2:) >= m(:n-1)),Non-monotonic mass data)

       ! Calculate coefficients

       x = r/R_star

       where(r /= 0._WP)
          V_x2 = G_GRAVITY*m*rho/(p*r*x**2)
       elsewhere
          V_x2 = 4._WP*PI*G_GRAVITY*rho**2*R_star**2/(3._WP*p)
       end where

       V = V_x2*x**2

       c_p = p*delta/(rho*T*nabla_ad)

       c_rad = 16._WP*PI*A_RADIATION*C_LIGHT*T**4*R_star*nabla*V_x2/(3._WP*kappa*rho*L_star)
       c_thm = 4._WP*PI*rho*T*c_p*SQRT(G_GRAVITY*M_star/R_star**3)*R_star**3/L_star

       kappa_ad = nabla_ad*kappa_T + kappa_rho/Gamma_1
       kappa_S = kappa_T - delta*kappa_rho

       c_dif = (kappa_ad-4._WP*nabla_ad)*V*nabla + nabla_ad*(dlny_dlnx_(x, nabla_ad)+V)

       epsilon_ad = nabla_ad*epsilon_T + epsilon_rho/Gamma_1
       epsilon_S = epsilon_T - delta*epsilon_rho

       c_eps_ad = 4._WP*PI*rho*epsilon_ad*R_star**3/L_star
       c_eps_S = 4._WP*PI*rho*epsilon_S*R_star**3/L_star

       dtau_thm = 4._WP*PI*rho*r**2*T*c_p*SQRT(G_GRAVITY*M_star/R_star**3)/L_star

       tau_thm(n) = 0._WP

       do i = n-1,1,-1
          tau_thm(i) = tau_thm(i+1) + &
               0.5_WP*(dtau_thm(i+1) + dtau_thm(i))*(r(i+1) - r(i))
       end do

       ! Initialize the model

       ml = evol_model_t(M_star, R_star, L_star, r, m, p, rho, T, N2, &
                         Gamma_1, nabla_ad, delta, Omega_rot, &
                         deriv_type, .FALSE.)

       !$OMP PARALLEL SECTIONS
       !$OMP SECTION
       call ml%set_sp_(x, c_rad, deriv_type, J_C_RAD)
       !$OMP SECTION
       call ml%set_sp_(x, c_thm, deriv_type, J_C_THM)
       !$OMP SECTION
       call ml%set_sp_(x, c_dif, deriv_type, J_C_DIF)
       !$OMP SECTION
       call ml%set_sp_(x, c_eps_ad, deriv_type, J_C_EPS_AD)
       !$OMP SECTION
       call ml%set_sp_(x, c_eps_S, deriv_type, J_C_EPS_S)
       !$OMP SECTION
       call ml%set_sp_(x, nabla, deriv_type, J_NABLA)
       !$OMP SECTION
       call ml%set_sp_(x, kappa_S, deriv_type, J_KAPPA_S)
       !$OMP SECTION
       call ml%set_sp_(x, kappa_ad, deriv_type, J_KAPPA_AD)
       !$OMP SECTION
       call ml%set_sp_(x, tau_thm, deriv_type, J_TAU_THM)
       !$OMP END PARALLEL SECTIONS

    endif

    ! Finish

    return

  contains

    function dlny_dlnx_ (x, y)

      real(WP), intent(in) :: x(:)
      real(WP), intent(in) :: y(:)
      real(WP)             :: dlny_dlnx_(SIZE(x))

      integer :: n
      integer :: i

      $CHECK_BOUNDS(SIZE(y),SIZE(x))

      ! Calculate the logarithmic derivative of y wrt x

      n = SIZE(x)

      dlny_dlnx_(1) = 0._WP

      do i = 2,n-1
         dlny_dlnx_(i) = x(i)*0.5_WP*((y(i)-y(i-1))/(x(i)-x(i-1)) + (y(i+1)-y(i))/(x(i+1)-x(i)))/y(i)
      end do

      dlny_dlnx_(n) = x(n)*(y(n)-y(n-1))/(x(n)-x(n-1))/y(n)

      ! Finish

    end function dlny_dlnx_

  end function evol_model_t_full_

!****

  subroutine set_sp_ (this, x, y, deriv_type, i)

    class(evol_model_t), intent(inout) :: this
    real(WP), intent(in)               :: x(:)
    real(WP), intent(in)               :: y(:)
    character(LEN=*), intent(in)       :: deriv_type
    integer, intent(in)                :: i

    $CHECK_BOUNDS(SIZE(y),SIZE(x))

    ! Set up the i'th spline with the provided data

    this%sp(i) = spline_t(x, y, deriv_type, dy_dx_a=0._WP)

    this%sp_def(i) = .TRUE.

    ! Finish

    return

  end subroutine set_sp_

!****
  
  function prep_center_ (x, y) result (y_prep)
      
    real(WP), intent(in) :: x(:)
    real(WP), intent(in) :: y(:)
    real(WP)             :: y_prep(SIZE(y)+1)

    real(WP) :: y_0

    $CHECK_BOUNDS(SIZE(x),SIZE(y))

    $ASSERT(SIZE(y) >= 2,Insufficient grid points)

    ! Use parabola fitting to interpolate y at the center
      
    y_0 = (x(2)**2*y(1) - x(1)**2*y(2))/(x(2)**2 - x(1)**2)

    ! Preprend this to the array

    y_prep = [y_0,y]

    ! Finish

    return

  end function prep_center_

!****

  subroutine regularize_data_ (r, m, p, rho, Gamma_1, N2, deriv_type, m_reg, p_reg, N2_reg)

    real(WP), intent(in)     :: r(:)
    real(WP), intent(in)     :: m(:)
    real(WP), intent(in)     :: p(:)
    real(WP), intent(in)     :: rho(:)
    real(WP), intent(in)     :: Gamma_1(:)
    real(WP), intent(in)     :: N2(:)
    character(*), intent(in) :: deriv_type
    real(WP), intent(out)    :: m_reg(:)
    real(WP), intent(out)    :: p_reg(:)
    real(WP), intent(out)    :: N2_reg(:)

    type(spline_t) :: sp_rho
    type(spline_t) :: sp_dm
    type(spline_t) :: sp_N2
    integer        :: n
    logical        :: N2_mask(SIZE(r))
    real(WP)       :: dlnrho_dlnr(SIZE(r))
    real(WP)       :: g_r(SIZE(r))

    $CHECK_BOUNDS(SIZE(m),SIZE(r))
    $CHECK_BOUNDS(SIZE(p),SIZE(r))
    $CHECK_BOUNDS(SIZE(rho),SIZE(r))
    $CHECK_BOUNDS(SIZE(Gamma_1),SIZE(r))
    $CHECK_BOUNDS(SIZE(N2),SIZE(r))
    $CHECK_BOUNDS(SIZE(m_reg),SIZE(r))
    $CHECK_BOUNDS(SIZE(p_reg),SIZE(r))
    $CHECK_BOUNDS(SIZE(N2_reg),SIZE(r))

    ! Regularize the model

    ! Set up interpolating splines

    sp_rho = spline_t(r, rho, deriv_type, dy_dx_a=0._WP)
    sp_dm = spline_t(r, 4._WP*PI*r**2*rho, deriv_type, dy_dx_a=0._WP)

    n = SIZE(N2)

    N2_mask = [.TRUE.,N2(1:n-2) > 0._WP .AND. N2(2:n-1) < 0._WP .AND. N2(3:n) > 0._WP,.TRUE.]

    sp_N2 = spline_t(PACK(r, N2_mask), PACK(N2, N2_mask), deriv_type, dy_dx_a=0._WP)

    ! Recalculate m

    m_reg = sp_dm%integ()

    ! Calculate dlnrho/dlnr

    dlnrho_dlnr = r*sp_rho%deriv()/rho

    ! Calculate g/r

    where (r /= 0._WP)
       g_r = G_GRAVITY*m_reg/r**3
    elsewhere
       g_r = 4._WP*PI*G_GRAVITY*rho
    endwhere

    ! Recalculate N2

    N2_reg = sp_N2%interp(r)

    ! Recalculate p

    where (r /= 0._WP)
       p_reg = -rho*g_r*r**2/(Gamma_1*(N2_reg/g_r + dlnrho_dlnr))
    endwhere

    where (r == 0._WP)
       p_reg = MAXVAL(p_reg, MASK=r /= 0._WP)
    endwhere

    $ASSERT(ALL(p_reg > 0._WP),Negative regularized pressure)

    ! Finish

    return

  end subroutine regularize_data_

!****

  $define $PROC $sub

  $local $NAME $1

  function ${NAME}_1_ (this, x) result ($NAME)

    class(evol_model_t), intent(in) :: this
    real(WP), intent(in)            :: x
    real(WP)                        :: $NAME

    integer :: j

    ! Interpolate $NAME

    j = J_$eval(uc($NAME))

    if(this%sp_def(j)) then

       if(ASSOCIATED(this%cc)) then
          $NAME = this%cc%lookup(j, x)
       else
          $NAME = this%sp(j)%interp(x)
       endif

    else

       $ABORT($NAME is undefined)

    endif
       
    ! Finish

    return

  end function ${NAME}_1_

  function ${NAME}_v_ (this, x) result ($NAME)

    class(evol_model_t), intent(in) :: this
    real(WP), intent(in)            :: x(:)
    real(WP)                        :: $NAME(SIZE(x))

    integer :: j

    ! Interpolate $NAME

    j = J_$eval(uc($NAME))
    
    if(this%sp_def(j)) then

       $NAME = this%sp(j)%interp(x)

    else

       $ABORT($NAME is undefined)

    endif

    ! Finish

    return

  end function ${NAME}_v_

  $endsub

  $PROC(m)
  $PROC(p)
  $PROC(rho)
  $PROC(T)
  $PROC(V)
  $PROC(As)
  $PROC(c_1)
  $PROC(nabla_ad)
  $PROC(delta)
  $PROC(Omega_rot)
  $PROC(nabla)
  $PROC(c_rad)
  $PROC(c_thm)
  $PROC(c_dif)
  $PROC(c_eps_ad)
  $PROC(c_eps_S)
  $PROC(kappa_S)
  $PROC(kappa_ad)
  $PROC(tau_thm)

!****

  $define $DPROC $sub

  $local $NAME $1

  function d${NAME}_1_ (this, x) result (d$NAME)

    class(evol_model_t), intent(in) :: this
    real(WP), intent(in)            :: x
    real(WP)                        :: d$NAME

    integer :: j
    integer :: j_d

    ! Interpolate dln$NAME/dlnx

    j = J_$eval(uc($NAME))
    j_d = J_D$eval(uc($NAME))

    if(this%sp_def(j)) then
    
       if(ASSOCIATED(this%cc)) then
          d$NAME = this%cc%lookup(j_d, x)
       else
          if(x > 0._WP) then
             d$NAME = x*this%sp(j)%deriv(x)/this%sp(j)%interp(x)
          else
             d$NAME = 0._WP
          endif
       endif

    else

       $ABORT($NAME is undefined)

    endif

    ! Finish

    return

  end function d${NAME}_1_

  function d${NAME}_v_ (this, x) result (d$NAME)

    class(evol_model_t), intent(in) :: this
    real(WP), intent(in)            :: x(:)
    real(WP)                        :: d$NAME(SIZE(x))

    integer :: j

    ! Interpolate dln$NAME/dlnx

    j = J_$eval(uc($NAME))

    if(this%sp_def(j)) then

       where(x > 0._WP)
          d$NAME = x*this%sp(j)%deriv(x)/this%sp(j)%interp(x)
       elsewhere
          d$NAME = 0._WP
       endwhere

    else

       $ABORT($NAME is undefined)

    endif
       
    ! Finish

    return

  end function d${NAME}_v_

  $endsub

  $DPROC(c_rad)

!****

  function U_1_ (this, x) result (U)

    class(evol_model_t), intent(in) :: this
    real(WP), intent(in)            :: x
    real(WP)                        :: U

    ! Calculate U. If implicit_U is .TRUE., use the c_1 based
    ! expression; this ensures that the correct relation between U and
    ! c_1 is preserved (see, e.g., eqn. 18 of Takata 2006, Proc. SOHO
    ! 18/GONG 2006/HELAS I, p. 26)

    if(ASSOCIATED(this%cc)) then

       U = this%cc%lookup(J_U, x)

    else

       if(implicit_U) then
          U = 3._WP - x*this%sp(J_C_1)%deriv(x)/this%sp(J_C_1)%interp(x)
       else
          U =  this%sp(J_U)%interp(x)
       endif

    endif

    ! Finish

    return

  end function U_1_

!****

  function U_v_ (this, x) result (U)

    class(evol_model_t), intent(in) :: this
    real(WP), intent(in)            :: x(:)
    real(WP)                        :: U(SIZE(x))

    ! Calculate U. If implicit_U is .TRUE., use the c_1 based
    ! expression; this ensures that the correct relation between U and
    ! c_1 is preserved (see, e.g., eqn. 18 of Takata 2006, Proc. SOHO
    ! 18/GONG 2006/HELAS I, p. 26)

    if(implicit_U) then
       U = 3._WP - x*this%sp(J_C_1)%deriv(x)/this%sp(J_C_1)%interp(x)
    else
       U =  this%sp(J_U)%interp(x)
    endif

    ! Finish

    return

  end function U_v_

!****

  function Gamma_1_1_ (this, x) result (Gamma_1)

    class(evol_model_t), intent(in) :: this
    real(WP), intent(in)            :: x
    real(WP)                        :: Gamma_1

    ! Calculate Gamma_1. If implicit_Gamma_1 is .TRUE., derive from
    ! other structure coefficients

    if(ASSOCIATED(this%cc)) then

       Gamma_1 = this%cc%lookup(J_GAMMA_1, x)

    else

       if(implicit_Gamma_1 .AND. x /= 0._WP) then

          Gamma_1 = this%V(x)/(-this%As(x) + this%U(x) + this%V(x) - 1._WP - &
                               x*this%sp(J_V)%deriv(x)/this%V(x))

       else
       
          Gamma_1 = this%sp(J_GAMMA_1)%interp(x)

       endif

    endif

    ! Finish

    return

  end function Gamma_1_1_

!****

  function Gamma_1_v_ (this, x) result (Gamma_1)

    class(evol_model_t), intent(in) :: this
    real(WP), intent(in)            :: x(:)
    real(WP)                        :: Gamma_1(SIZE(x))

    ! Calculate Gamma_1. If implicit_Gamma_1 is .TRUE., derive from
    ! other structure coefficients

    where(implicit_Gamma_1 .AND. x /= 0._WP)

       Gamma_1 = this%V(x)/(-this%As(x) + this%U(x) + this%V(x) - 1._WP - &
                            x*this%sp(J_V)%deriv(x)/this%V(x))

    elsewhere

       Gamma_1 = this%sp(J_GAMMA_1)%interp(x)

    end where

    ! Finish

    return

  end function Gamma_1_v_
       
!****

  function pi_c_ (this) result (pi_c)

    class(evol_model_t), intent(in) :: this
    real(WP)                         :: pi_c

    ! Calculate pi_c = V/x^2 as x -> 0

    pi_c = 4._WP*PI*G_GRAVITY*this%rho(0._WP)**2*this%R_star**2/(3._WP*this%p(0._WP))

    ! Finish

    return

  end function pi_c_

!****

  function is_zero_ (this, x) result (is_zero)

    class(evol_model_t), intent(in) :: this
    real(WP), intent(in)            :: x
    logical                         :: is_zero

    logical :: p_zero
    logical :: rho_zero

    ! Determine whether the point at x has a vanishing pressure and/or
    ! density

    if(this%sp_def(J_P)) then
       p_zero = this%p(x) == 0._WP
    else
       p_zero = .FALSE.
    endif

    if(this%sp_def(J_RHO)) then
       rho_zero = this%rho(x) == 0._WP
    else
       rho_zero = .FALSE.
    endif

    is_zero = P_ZERO .OR. RHO_ZERO

    ! Finish

    return

  end function is_zero_

!****

  subroutine attach_cache_ (this, cc)

    class(evol_model_t), intent(inout)    :: this
    class(cocache_t), pointer, intent(in) :: cc

    ! Attach a coefficient cache

    this%cc => cc

    ! Finish

    return

  end subroutine attach_cache_

!****

  subroutine detach_cache_ (this)

    class(evol_model_t), intent(inout) :: this

    ! Detach the coefficient cache

    this%cc => null()

    ! Finish

    return

  end subroutine detach_cache_

!****

  subroutine fill_cache_ (this, x)

    class(evol_model_t), intent(inout) :: this
    real(WP), intent(in)               :: x(:)

    real(WP) :: c(N_J,SIZE(x))

    $ASSERT_DEBUG(ASSOCIATED(this%cc),No cache attached)

    ! Fill the coefficient cache

    !$OMP PARALLEL SECTIONS
    !$OMP SECTION
    if (this%sp_def(J_M)) c(J_M,:) = this%m(x)
    !$OMP SECTION
    if (this%sp_def(J_P)) c(J_P,:) = this%p(x)
    !$OMP SECTION
    if (this%sp_def(J_RHO)) c(J_RHO,:) = this%rho(x)
    !$OMP SECTION
    if (this%sp_def(J_T)) c(J_T,:) = this%T(x)
    !$OMP SECTION
    if (this%sp_def(J_V)) c(J_V,:) = this%V(x)
    !$OMP SECTION
    if (this%sp_def(J_AS)) c(J_AS,:) = this%As(x)
    !$OMP SECTION
    if (this%sp_def(J_U)) c(J_U,:) = this%U(x)
    !$OMP SECTION
    if (this%sp_def(J_C_1)) c(J_C_1,:) = this%c_1(x)
    !$OMP SECTION
    if (this%sp_def(J_GAMMA_1)) c(J_GAMMA_1,:) = this%Gamma_1(x)
    !$OMP SECTION
    if (this%sp_def(J_NABLA_AD)) c(J_NABLA_AD,:) = this%nabla_ad(x)
    !$OMP SECTION
    if (this%sp_def(J_DELTA)) c(J_DELTA,:) = this%delta(x)
    !$OMP SECTION
    if (this%sp_def(J_OMEGA_ROT)) c(J_OMEGA_ROT,:) = this%Omega_rot(x)
    !$OMP SECTION
    if (this%sp_def(J_NABLA)) c(J_NABLA,:) = this%nabla(x)
    !$OMP SECTION
    if (this%sp_def(J_C_RAD)) c(J_C_RAD,:) = this%c_rad(x)
    !$OMP SECTION
    if (this%sp_def(J_C_RAD)) c(J_DC_RAD,:) = this%dc_rad(x)
    !$OMP SECTION
    if (this%sp_def(J_C_THM)) c(J_C_THM,:) = this%c_thm(x)
    !$OMP SECTION
    if (this%sp_def(J_C_DIF)) c(J_C_DIF,:) = this%c_dif (x)
    !$OMP SECTION
    if (this%sp_def(J_C_EPS_AD)) c(J_C_EPS_AD,:) = this%c_eps_ad(x)
    !$OMP SECTION
    if (this%sp_def(J_C_EPS_S)) c(J_C_EPS_S,:) = this%c_eps_S(x)
    !$OMP SECTION
    if (this%sp_def(J_KAPPA_S)) c(J_KAPPA_S,:) = this%kappa_S(x)
    !$OMP SECTION
    if (this%sp_def(J_KAPPA_AD)) c(J_KAPPA_AD,:) = this%kappa_ad(x)
    !$OMP SECTION
    if (this%sp_def(J_TAU_THM)) c(J_TAU_THM,:) = this%tau_thm(x)
    !$OMP END PARALLEL SECTIONS

    this%cc = cocache_t(x, c)

    ! Finish

    return

  end subroutine fill_cache_

!****

  $if ($MPI)

  subroutine bcast_ (ml, root_rank)

    type(evol_model_t), intent(inout) :: ml
    integer, intent(in)               :: root_rank

    ! Broadcast the evol_model_t

    call bcast_alloc(ml%sp, root_rank)
    call bcast_alloc(ml%sp_def, root_rank)

    call bcast(ml%M_star, root_rank)
    call bcast(ml%R_star, root_rank)
    call bcast(ml%L_star, root_rank)

    call bcast(ml%p_c, root_rank)
    call bcast(ml%rho_c, root_rank)

    if(MPI_RANK /= root_rank) ml%cc => null()

    ! Finish

    return

  end subroutine bcast_

  $endif

end module gyre_evol_model
