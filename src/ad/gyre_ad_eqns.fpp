! Module   : gyre_ad_eqns
! Purpose  : adiabatic differential equations
!
! Copyright 2013-2016 Rich Townsend
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

module gyre_ad_eqns

  ! Uses

  use core_kinds

  use gyre_ad_vars
  use gyre_eqns
  use gyre_grid
  use gyre_model
  use gyre_mode_par
  use gyre_osc_par
  use gyre_point
  use gyre_rot
  use gyre_rot_factory

  use ISO_FORTRAN_ENV

  ! No implicit typing

  implicit none

  ! Derived-type definitions

  type, extends (r_eqns_t) :: ad_eqns_t
     private
     class(model_t), pointer     :: ml => null()
     class(r_rot_t), allocatable :: rt
     type(ad_vars_t)             :: vr
     real(WP)                    :: alpha_gr
     real(WP)                    :: alpha_om
   contains
     private
     procedure, public :: A
     procedure, public :: xA
  end type ad_eqns_t

  ! Interfaces

  interface ad_eqns_t
     module procedure ad_eqns_t_
  end interface ad_eqns_t

  ! Access specifiers

  private

  public :: ad_eqns_t

  ! Procedures

contains

  function ad_eqns_t_ (ml, gr, md_p, os_p) result (eq)

    class(model_t), pointer, intent(in) :: ml
    type(grid_t), intent(in)            :: gr
    type(mode_par_t), intent(in)        :: md_p
    type(osc_par_t), intent(in)         :: os_p
    type(ad_eqns_t)                     :: eq

    ! Construct the ad_eqns_t

    eq%ml => ml

    allocate(eq%rt, SOURCE=r_rot_t(ml, gr, md_p, os_p))
    eq%vr = ad_vars_t(ml, gr, md_p, os_p)

    if (os_p%cowling_approx) then
       eq%alpha_gr = 0._WP
    else
       eq%alpha_gr = 1._WP
    endif

    select case (os_p%time_factor)
    case ('OSC')
       eq%alpha_om = 1._WP
    case ('EXP')
       eq%alpha_om = -1._WP
    case default
       $ABORT(Invalid time_factor)
    end select

    eq%n_e = 4

    ! Finish

    return

  end function ad_eqns_t_

  !****

  function A (this, pt, omega)

    class(ad_eqns_t), intent(in) :: this
    type(point_t), intent(in)    :: pt
    real(WP), intent(in)         :: omega
    real(WP)                     :: A(this%n_e,this%n_e)
    
    ! Evaluate the RHS matrix

    A = this%xA(pt, omega)/pt%x

    ! Finish

    return

  end function A

  !****

  function xA (this, pt, omega)

    class(ad_eqns_t), intent(in) :: this
    type(point_t), intent(in)    :: pt
    real(WP), intent(in)         :: omega
    real(WP)                     :: xA(this%n_e,this%n_e)

    real(WP) :: V_g
    real(WP) :: U
    real(WP) :: As
    real(WP) :: c_1
    real(WP) :: lambda
    real(WP) :: l_i
    real(WP) :: omega_c
    real(WP) :: alpha_gr
    real(WP) :: alpha_om
    
    ! Evaluate the log(x)-space RHS matrix

    ! Calculate coefficients
    
    V_g = this%ml%V_2(pt)*pt%x**2/this%ml%Gamma_1(pt)
    U = this%ml%U(pt)
    As = this%ml%As(pt)
    c_1 = this%ml%c_1(pt)

    lambda = this%rt%lambda(pt, omega)
    l_i = this%rt%l_i(omega)

    omega_c = this%rt%omega_c(pt, omega)

    alpha_gr = this%alpha_gr
    alpha_om = this%alpha_om

    ! Set up the matrix

    xA(1,1) = V_g - 1._WP - l_i
    xA(1,2) = lambda/(c_1*alpha_om*omega_c**2) - V_g
    xA(1,3) = alpha_gr*(lambda/(c_1*alpha_om*omega_c**2))
    xA(1,4) = alpha_gr*(0._WP)

    xA(2,1) = c_1*alpha_om*omega_c**2 - As
    xA(2,2) = As - U + 3._WP - l_i
    xA(2,3) = alpha_gr*(0._WP)
    xA(2,4) = alpha_gr*(-1._WP)

    xA(3,1) = alpha_gr*(0._WP)
    xA(3,2) = alpha_gr*(0._WP)
    xA(3,3) = alpha_gr*(3._WP - U - l_i)
    xA(3,4) = alpha_gr*(1._WP)

    xA(4,1) = alpha_gr*(U*As)
    xA(4,2) = alpha_gr*(U*V_g)
    xA(4,3) = alpha_gr*(lambda)
    xA(4,4) = alpha_gr*(-U - l_i + 2._WP)

    ! Apply the variables transformation

    xA = MATMUL(this%vr%G(pt, omega), MATMUL(xA, this%vr%H(pt, omega)) - &
                                                 this%vr%dH(pt, omega))

    ! Finish

    return

  end function xA
  
end module gyre_ad_eqns
