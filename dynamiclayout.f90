! DynamicLayout Fortran 2003+ API — generate layout JSON from Fortran code.
!
! Single-file module. Zero dependencies outside intrinsic functions.
! Works on gfortran 8+, ifort 19+.
!
! Example:
!   use dynamiclayout
!   type(dl_builder) :: b
!   b = dl_begin("My Page")
!   call dl_fieldset(b, "Info")
!   call dl_label(b, "Hello from Fortran!")
!   call dl_end_fieldset(b)
!   call dl_button(b, "ok", "OK", "primary", .true.)
!   call dl_end(b)

module dynamiclayout
  implicit none
  private
  public :: dl_builder, dl_begin, dl_end
  public :: dl_fieldset, dl_end_fieldset, dl_row, dl_end_row, dl_col, dl_end_col
  public :: dl_label, dl_alert, dl_badge, dl_spacer
  public :: dl_input, dl_textarea, dl_checkbox, dl_rating
  public :: dl_button, dl_section

  integer, parameter :: BUFSZ = 16384

  type :: dl_builder
     character(len=BUFSZ) :: buf
     integer :: pos = 0
     integer :: depth = 0
     logical :: comma = .false.
     integer :: counter = 0
  end type dl_builder

contains

  subroutine dl_putc(b, c)
    type(dl_builder), intent(inout) :: b
    character, intent(in) :: c
    b%pos = b%pos + 1
    b%buf(b%pos:b%pos) = c
  end subroutine dl_putc

  subroutine dl_puts(b, s)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: s
    integer :: i
    do i = 1, len_trim(s)
       call dl_putc(b, s(i:i))
    end do
  end subroutine dl_puts

  subroutine dl_indent(b)
    type(dl_builder), intent(inout) :: b
    integer :: i
    call dl_putc(b, new_line('a'))
    do i = 1, b%depth
       call dl_puts(b, "  ")
    end do
  end subroutine dl_indent

  subroutine dl_cm(b)
    type(dl_builder), intent(inout) :: b
    if (b%comma) call dl_putc(b, ',')
    b%comma = .false.
  end subroutine dl_cm

  subroutine dl_escape(b, s)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: s
    integer :: i
    call dl_putc(b, '"')
    do i = 1, len_trim(s)
       select case (s(i:i))
       case ('"');  call dl_puts(b, '\"')
       case ('\');  call dl_puts(b, '\\')
       case default; call dl_putc(b, s(i:i))
       end select
    end do
    call dl_putc(b, '"')
  end subroutine dl_escape

  subroutine dl_kv(b, key, val)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: key, val
    call dl_cm(b); call dl_putc(b, ','); call dl_indent(b)
    call dl_escape(b, key); call dl_puts(b, ": "); call dl_escape(b, val)
    b%comma = .true.
  end subroutine dl_kv

  subroutine dl_kvint(b, key, val)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: key
    integer, intent(in) :: val
    character(len=16) :: tmp
    write(tmp, '(I0)') val
    call dl_cm(b); call dl_putc(b, ','); call dl_indent(b)
    call dl_escape(b, key); call dl_puts(b, ": " // trim(tmp))
    b%comma = .true.
  end subroutine dl_kvint

  subroutine dl_kvbool(b, key)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: key
    call dl_cm(b); call dl_putc(b, ','); call dl_indent(b)
    call dl_escape(b, key); call dl_puts(b, ": true")
    b%comma = .true.
  end subroutine dl_kvbool

  subroutine dl_obj(b)
    type(dl_builder), intent(inout) :: b
    call dl_cm(b); call dl_putc(b, ','); call dl_indent(b)
    call dl_putc(b, '{'); b%depth = b%depth + 1; b%comma = .false.
  end subroutine dl_obj

  subroutine dl_co(b)
    type(dl_builder), intent(inout) :: b
    b%depth = b%depth - 1; call dl_indent(b); call dl_putc(b, '}'); b%comma = .true.
  end subroutine dl_co

  subroutine dl_arr(b, key)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: key
    call dl_cm(b); call dl_putc(b, ','); call dl_indent(b)
    call dl_escape(b, key); call dl_puts(b, ": [")
    b%depth = b%depth + 1; b%comma = .false.
  end subroutine dl_arr

  subroutine dl_ca(b)
    type(dl_builder), intent(inout) :: b
    b%depth = b%depth - 1; call dl_indent(b); call dl_putc(b, ']'); b%comma = .true.
  end subroutine dl_ca

  function dl_key(b, prefix) result(k)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: prefix
    character(len=32) :: k
    b%counter = b%counter + 1
    write(k, '(A, A, I0)') trim(prefix), '_', b%counter
  end function dl_key

  ! ── Public API ──

  function dl_begin(title) result(b)
    character(len=*), intent(in) :: title
    type(dl_builder) :: b
    b%pos = 0; b%depth = 0; b%comma = .false.; b%counter = 0
    call dl_puts(b, '{"ui":{')
    b%depth = 2; b%comma = .false.
    call dl_kv(b, "title", title)
    call dl_arr(b, "layout")
  end function dl_begin

  subroutine dl_end(b)
    type(dl_builder), intent(inout) :: b
    call dl_ca(b)
    b%comma = .false.; call dl_putc(b, ',')
    call dl_puts(b, '"translations":{},')
    call dl_puts(b, '"userAccess":{"cancel":true}')
    call dl_puts(b, '}}')
    call dl_putc(b, char(0))
  end subroutine dl_end

  ! Containers
  subroutine dl_fieldset(b, title)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: title
    call dl_obj(b)
    call dl_kv(b, "type", "FIELDSET")
    call dl_kv(b, "key", dl_key(b, "fs"))
    call dl_kv(b, "title", title)
    call dl_arr(b, "content")
  end subroutine dl_fieldset

  subroutine dl_end_fieldset(b)
    type(dl_builder), intent(inout) :: b
    call dl_ca(b); call dl_co(b)
  end subroutine dl_end_fieldset

  subroutine dl_row(b)
    type(dl_builder), intent(inout) :: b
    call dl_obj(b)
    call dl_kv(b, "type", "ROW")
    call dl_kv(b, "key", dl_key(b, "r"))
    call dl_arr(b, "content")
  end subroutine dl_row

  subroutine dl_end_row(b)
    type(dl_builder), intent(inout) :: b
    call dl_ca(b); call dl_co(b)
  end subroutine dl_end_row

  subroutine dl_col(b, xs, md)
    type(dl_builder), intent(inout) :: b
    integer, intent(in) :: xs, md
    call dl_obj(b)
    call dl_kv(b, "type", "COL")
    call dl_kv(b, "key", dl_key(b, "c"))
    if (xs > 0 .or. md > 0) then
       call dl_cm(b); call dl_putc(b, ','); call dl_indent(b)
       call dl_puts(b, '"length":{')
       if (xs > 0) then
          call dl_puts(b, '"xs":'); call dl_kvint(b, "", xs)
          b%comma = .false.  ! hack: kvint adds trailing comma we don't want
       end if
       if (md > 0) then
          if (xs > 0) call dl_putc(b, ',')
          call dl_puts(b, '"md":'); call dl_kvint(b, "", md)
          b%comma = .false.
       end if
       call dl_puts(b, '}')
       b%comma = .true.
    end if
    call dl_arr(b, "content")
  end subroutine dl_col

  subroutine dl_end_col(b)
    type(dl_builder), intent(inout) :: b
    call dl_ca(b); call dl_co(b)
  end subroutine dl_end_col

  ! Display
  subroutine dl_label(b, text)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: text
    call dl_obj(b)
    call dl_kv(b, "type", "LABEL"); call dl_kv(b, "key", dl_key(b, "l"))
    call dl_kv(b, "label", text); call dl_co(b)
  end subroutine dl_label

  subroutine dl_alert(b, msg, color)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: msg, color
    call dl_obj(b)
    call dl_kv(b, "type", "ALERT"); call dl_kv(b, "key", dl_key(b, "a"))
    call dl_kv(b, "message", msg); call dl_kv(b, "color", color); call dl_co(b)
  end subroutine dl_alert

  subroutine dl_badge(b, title, color)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: title, color
    call dl_obj(b)
    call dl_kv(b, "type", "BADGE"); call dl_kv(b, "key", dl_key(b, "bd"))
    call dl_kv(b, "title", title); call dl_kv(b, "color", color); call dl_co(b)
  end subroutine dl_badge

  subroutine dl_spacer(b, px)
    type(dl_builder), intent(inout) :: b
    integer, intent(in) :: px
    call dl_obj(b)
    call dl_kv(b, "type", "SPACER"); call dl_kv(b, "key", dl_key(b, "sp"))
    call dl_kvint(b, "width", px); call dl_co(b)
  end subroutine dl_spacer

  ! Inputs
  subroutine dl_input(b, id, label, required)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: id, label
    logical, intent(in) :: required
    call dl_obj(b)
    call dl_kv(b, "type", "INPUT"); call dl_kv(b, "key", dl_key(b, "i"))
    call dl_kv(b, "id", id); call dl_kv(b, "label", label)
    if (required) call dl_kvbool(b, "required")
    call dl_co(b)
  end subroutine dl_input

  subroutine dl_textarea(b, id, label, rows)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: id, label
    integer, intent(in) :: rows
    call dl_obj(b)
    call dl_kv(b, "type", "TEXTAREA"); call dl_kv(b, "key", dl_key(b, "ta"))
    call dl_kv(b, "id", id); call dl_kv(b, "label", label)
    if (rows > 0) call dl_kvint(b, "rows", rows)
    call dl_co(b)
  end subroutine dl_textarea

  subroutine dl_checkbox(b, id, label)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: id, label
    call dl_obj(b)
    call dl_kv(b, "type", "CHECKBOX"); call dl_kv(b, "key", dl_key(b, "cb"))
    call dl_kv(b, "id", id); call dl_kv(b, "label", label); call dl_co(b)
  end subroutine dl_checkbox

  subroutine dl_rating(b, id, label)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: id, label
    call dl_obj(b)
    call dl_kv(b, "type", "RATING"); call dl_kv(b, "key", dl_key(b, "rt"))
    call dl_kv(b, "id", id); call dl_kv(b, "label", label); call dl_co(b)
  end subroutine dl_rating

  ! Actions
  subroutine dl_button(b, id, title, color, is_default)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: id, title, color
    logical, intent(in) :: is_default
    call dl_obj(b)
    call dl_kv(b, "type", "BUTTON"); call dl_kv(b, "key", dl_key(b, "btn"))
    call dl_kv(b, "id", id); call dl_kv(b, "title", title); call dl_kv(b, "color", color)
    if (is_default) call dl_kvbool(b, "default")
    call dl_co(b)
  end subroutine dl_button

  ! Shortcuts
  subroutine dl_section(b, title, text)
    type(dl_builder), intent(inout) :: b
    character(len=*), intent(in) :: title, text
    call dl_fieldset(b, title)
    call dl_label(b, text)
    call dl_end_fieldset(b)
  end subroutine dl_section

end module dynamiclayout
