# DynamicLayout Perl API — generate layout JSON from Perl code.
#
# Single-file module. Zero dependencies outside Perl 5.10+ core.
# Uses only built-in modules (no CPAN).
#
# Example:
#   use DynamicLayout;
#   my $b = DynamicLayout::begin("My Page");
#   $b->fieldset("Info")->label("Hello from Perl!")->end;
#   $b->button("ok", "OK", "primary", 1);
#   print $b->end;

package DynamicLayout;
use strict; use warnings; use 5.010;
use Exporter 'import';
our @EXPORT = qw(begin);

sub begin {
    my ($title) = @_;
    my $self = bless {
        buf    => '',
        depth  => 0,
        comma  => 0,
        cnt    => 0,
    }, __PACKAGE__;
    $self->_puts('{"ui":{');
    $self->{depth} = 2; $self->{comma} = 0;
    $self->_kv("title", $title);
    $self->_arr("layout");
    return $self;
}

sub _put  { $_[0]->{buf} .= $_[1] }
sub _puts { $_[0]->{buf} .= $_[1] }
sub _indent { my $s = shift; $s->_put("\n"); $s->_puts("  " x $s->{depth}) }
sub _cm { my $s = shift; $s->_put(',') if $s->{comma}; $s->{comma} = 0 }
sub _esc { my ($s, $t) = @_; $t =~ s/([\\"])/\\$1/g; $s->_put('"'); $s->_puts($t); $s->_put('"') }
sub _kv { my ($s, $k, $v) = @_; return unless defined $v; $s->_cm; $s->_put(','); $s->_indent; $s->_esc($k); $s->_puts(": "); $s->_esc($v); $s->{comma} = 1 }
sub _kvint { my ($s, $k, $v) = @_; $s->_cm; $s->_put(','); $s->_indent; $s->_esc($k); $s->_puts(": $v"); $s->{comma} = 1 }
sub _kvbool { my ($s, $k) = @_; $s->_cm; $s->_put(','); $s->_indent; $s->_esc($k); $s->_puts(": true"); $s->{comma} = 1 }
sub _obj { my $s = shift; $s->_cm; $s->_put(','); $s->_indent; $s->_put('{'); $s->{depth}++; $s->{comma} = 0 }
sub _co { my $s = shift; $s->{depth}--; $s->_indent; $s->_put('}'); $s->{comma} = 1 }
sub _arr { my ($s, $k) = @_; $s->_cm; $s->_put(','); $s->_indent; $s->_esc($k); $s->_puts(": ["); $s->{depth}++; $s->{comma} = 0 }
sub _ca { my $s = shift; $s->{depth}--; $s->_indent; $s->_put(']'); $s->{comma} = 1 }
sub _key { my ($s, $p) = @_; $s->{cnt}++; return "${p}_$s->{cnt}" }

sub fieldset { my ($s, $t) = @_; $s->_obj; $s->_kv("type","FIELDSET"); $s->_kv("key",$s->_key("fs")); $s->_kv("title",$t); $s->_arr("content"); $s }
sub end { my $s = shift; $s->_ca; $s->_co; $s }
sub row { my $s = shift; $s->_obj; $s->_kv("type","ROW"); $s->_kv("key",$s->_key("r")); $s->_arr("content"); $s }
sub end_row { shift->end }
sub label { my ($s, $t) = @_; $s->_obj; $s->_kv("type","LABEL"); $s->_kv("key",$s->_key("l")); $s->_kv("label",$t); $s->_co; $s }
sub alert { my ($s, $m, $c) = @_; $c ||= 'info'; $s->_obj; $s->_kv("type","ALERT"); $s->_kv("key",$s->_key("a")); $s->_kv("message",$m); $s->_kv("color",$c); $s->_co; $s }
sub badge { my ($s, $t, $c) = @_; $c ||= 'primary'; $s->_obj; $s->_kv("type","BADGE"); $s->_kv("key",$s->_key("bd")); $s->_kv("title",$t); $s->_kv("color",$c); $s->_co; $s }
sub spacer { my ($s, $px) = @_; $s->_obj; $s->_kv("type","SPACER"); $s->_kv("key",$s->_key("sp")); $s->_kvint("width",$px); $s->_co; $s }
sub input { my ($s, $id, $lb, $req) = @_; $s->_obj; $s->_kv("type","INPUT"); $s->_kv("key",$s->_key("i")); $s->_kv("id",$id); $s->_kv("label",$lb); $s->_kvbool("required") if $req; $s->_co; $s }
sub textarea { my ($s, $id, $lb, $r) = @_; $s->_obj; $s->_kv("type","TEXTAREA"); $s->_kv("key",$s->_key("ta")); $s->_kv("id",$id); $s->_kv("label",$lb); $s->_kvint("rows",$r) if $r; $s->_co; $s }
sub checkbox { my ($s, $id, $lb) = @_; $s->_obj; $s->_kv("type","CHECKBOX"); $s->_kv("key",$s->_key("cb")); $s->_kv("id",$id); $s->_kv("label",$lb); $s->_co; $s }
sub rating { my ($s, $id, $lb) = @_; $s->_obj; $s->_kv("type","RATING"); $s->_kv("key",$s->_key("rt")); $s->_kv("id",$id); $s->_kv("label",$lb); $s->_co; $s }
sub button { my ($s, $id, $t, $c, $d) = @_; $s->_obj; $s->_kv("type","BUTTON"); $s->_kv("key",$s->_key("btn")); $s->_kv("id",$id); $s->_kv("title",$t); $s->_kv("color",$c||'primary'); $s->_kvbool("default") if $d; $s->_co; $s }
sub section { my ($s, $t, $x) = @_; $s->fieldset($t)->label($x)->end }

sub end_layout {
    my $s = shift;
    $s->_ca;
    $s->{comma} = 0; $s->_put(',');
    $s->_puts('"translations":{},');
    $s->_puts('"userAccess":{"cancel":true}');
    $s->_puts('}}');
    return $s->{buf};
}

1;
