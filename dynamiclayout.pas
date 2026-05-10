{ DynamicLayout Free Pascal API — generate layout JSON from Pascal code.
  Single-file unit. Zero dependencies. Works on FPC 3.2+, Delphi.
  Example:
    uses DynamicLayout;
    var b: TBuilder;
    b := BeginLayout('My Page');
    Fieldset(b, 'Info');
    Label(b, 'Hello from Pascal!');
    EndFieldset(b);
    Button(b, 'ok', 'OK', 'primary', true);
    WriteLn(EndLayout(b));
end. }

unit DynamicLayout;

{$mode objfpc}{$H+}

interface

type
  TBuilder = record
    Buf: AnsiString;
    Depth: Integer;
    Comma: Boolean;
    Cnt: Integer;
  end;

function BeginLayout(const Title: string): TBuilder;
function EndLayout(var B: TBuilder): AnsiString;

procedure Fieldset(var B: TBuilder; const Title: string);
procedure EndFieldset(var B: TBuilder);
procedure Row(var B: TBuilder);
procedure EndRow(var B: TBuilder);
procedure Label(var B: TBuilder; const Text: string);
procedure Alert(var B: TBuilder; const Msg, Color: string);
procedure Badge(var B: TBuilder; const Title, Color: string);
procedure Spacer(var B: TBuilder; Px: Integer);
procedure Input(var B: TBuilder; const Id, FieldLabel: string; Required: Boolean);
procedure Checkbox(var B: TBuilder; const Id, FieldLabel: string);
procedure Textarea(var B: TBuilder; const Id, FieldLabel: string; Rows: Integer);
procedure Rating(var B: TBuilder; const Id, FieldLabel: string);
procedure Button(var B: TBuilder; const Id, Title, Color: string; IsDefault: Boolean);
procedure Section(var B: TBuilder; const Title, Text: string);

implementation
uses SysUtils;

procedure Putc(var B: TBuilder; C: Char); begin B.Buf := B.Buf + C; end;
procedure Puts(var B: TBuilder; const S: string); begin B.Buf := B.Buf + S; end;
procedure Indent(var B: TBuilder); var I: Integer; begin Putc(B, #10); for I := 1 to B.Depth do Puts(B, '  '); end;
procedure Cm(var B: TBuilder); begin if B.Comma then Putc(B, ','); B.Comma := False; end;
procedure Esc(var B: TBuilder; const S: string); var C: Char; begin Putc(B, '"'); for C in S do case C of '"': Puts(B, '\"'); '\': Puts(B, '\\'); #10: Puts(B, '\n'); else Putc(B, C); end; Putc(B, '"'); end;
procedure Kv(var B: TBuilder; const K, V: string); begin Cm(B); Putc(B, ','); Indent(B); Esc(B, K); Puts(B, ': '); Esc(B, V); B.Comma := True; end;
procedure Kvint(var B: TBuilder; const K: string; V: Integer); begin Cm(B); Putc(B, ','); Indent(B); Esc(B, K); Puts(B, ': ' + IntToStr(V)); B.Comma := True; end;
procedure Kvbool(var B: TBuilder; const K: string); begin Cm(B); Putc(B, ','); Indent(B); Esc(B, K); Puts(B, ': true'); B.Comma := True; end;
procedure Obj(var B: TBuilder); begin Cm(B); Putc(B, ','); Indent(B); Putc(B, '{'); Inc(B.Depth); B.Comma := False; end;
procedure Co(var B: TBuilder); begin Dec(B.Depth); Indent(B); Putc(B, '}'); B.Comma := True; end;
procedure Arr(var B: TBuilder; const K: string); begin Cm(B); Putc(B, ','); Indent(B); Esc(B, K); Puts(B, ': ['); Inc(B.Depth); B.Comma := False; end;
procedure Ca(var B: TBuilder); begin Dec(B.Depth); Indent(B); Putc(B, ']'); B.Comma := True; end;
function Key(var B: TBuilder; const Prefix: string): string; begin Inc(B.Cnt); Result := Prefix + '_' + IntToStr(B.Cnt); end;

function BeginLayout(const Title: string): TBuilder;
begin
  Result.Buf := ''; Result.Depth := 0; Result.Comma := False; Result.Cnt := 0;
  Puts(Result, '{"ui":{'); Result.Depth := 2; Result.Comma := False;
  Kv(Result, 'title', Title); Arr(Result, 'layout');
end;

function EndLayout(var B: TBuilder): AnsiString;
begin
  Ca(B); B.Comma := False; Putc(B, ',');
  Puts(B, '"translations":{},'); Puts(B, '"userAccess":{"cancel":true}'); Puts(B, '}}');
  Result := B.Buf;
end;

procedure Fieldset(var B: TBuilder; const Title: string); begin Obj(B); Kv(B, 'type', 'FIELDSET'); Kv(B, 'key', Key(B, 'fs')); Kv(B, 'title', Title); Arr(B, 'content'); end;
procedure EndFieldset(var B: TBuilder); begin Ca(B); Co(B); end;
procedure Row(var B: TBuilder); begin Obj(B); Kv(B, 'type', 'ROW'); Kv(B, 'key', Key(B, 'r')); Arr(B, 'content'); end;
procedure EndRow(var B: TBuilder); begin Ca(B); Co(B); end;
procedure Label(var B: TBuilder; const Text: string); begin Obj(B); Kv(B, 'type', 'LABEL'); Kv(B, 'key', Key(B, 'l')); Kv(B, 'label', Text); Co(B); end;
procedure Alert(var B: TBuilder; const Msg, Color: string); begin Obj(B); Kv(B, 'type', 'ALERT'); Kv(B, 'key', Key(B, 'a')); Kv(B, 'message', Msg); Kv(B, 'color', Color); Co(B); end;
procedure Badge(var B: TBuilder; const Title, Color: string); begin Obj(B); Kv(B, 'type', 'BADGE'); Kv(B, 'key', Key(B, 'bd')); Kv(B, 'title', Title); Kv(B, 'color', Color); Co(B); end;
procedure Spacer(var B: TBuilder; Px: Integer); begin Obj(B); Kv(B, 'type', 'SPACER'); Kv(B, 'key', Key(B, 'sp')); Kvint(B, 'width', Px); Co(B); end;
procedure Input(var B: TBuilder; const Id, FieldLabel: string; Required: Boolean); begin Obj(B); Kv(B, 'type', 'INPUT'); Kv(B, 'key', Key(B, 'i')); Kv(B, 'id', Id); Kv(B, 'label', FieldLabel); if Required then Kvbool(B, 'required'); Co(B); end;
procedure Checkbox(var B: TBuilder; const Id, FieldLabel: string); begin Obj(B); Kv(B, 'type', 'CHECKBOX'); Kv(B, 'key', Key(B, 'cb')); Kv(B, 'id', Id); Kv(B, 'label', FieldLabel); Co(B); end;
procedure Textarea(var B: TBuilder; const Id, FieldLabel: string; Rows: Integer); begin Obj(B); Kv(B, 'type', 'TEXTAREA'); Kv(B, 'key', Key(B, 'ta')); Kv(B, 'id', Id); Kv(B, 'label', FieldLabel); if Rows > 0 then Kvint(B, 'rows', Rows); Co(B); end;
procedure Rating(var B: TBuilder; const Id, FieldLabel: string); begin Obj(B); Kv(B, 'type', 'RATING'); Kv(B, 'key', Key(B, 'rt')); Kv(B, 'id', Id); Kv(B, 'label', FieldLabel); Co(B); end;
procedure Button(var B: TBuilder; const Id, Title, Color: string; IsDefault: Boolean); begin Obj(B); Kv(B, 'type', 'BUTTON'); Kv(B, 'key', Key(B, 'btn')); Kv(B, 'id', Id); Kv(B, 'title', Title); Kv(B, 'color', Color); if IsDefault then Kvbool(B, 'default'); Co(B); end;
procedure Section(var B: TBuilder; const Title, Text: string); begin Fieldset(B, Title); Label(B, Text); EndFieldset(B); end;

end.
