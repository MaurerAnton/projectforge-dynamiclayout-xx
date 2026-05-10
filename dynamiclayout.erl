%% DynamicLayout Erlang API — generate layout JSON from Erlang code.
%%
%% Single-file module. Zero dependencies outside stdlib.
%% Works on OTP 24+.
%%
%% Example:
%%   B = dynamiclayout:begin("My Page"),
%%   B1 = dynamiclayout:fieldset(B, "Info"),
%%   B2 = dynamiclayout:label(B1, "Hello from Erlang!"),
%%   B3 = dynamiclayout:end_fieldset(B2),
%%   B4 = dynamiclayout:button(B3, "ok", "OK", "primary", true),
%%   io:format("~s~n", [dynamiclayout:end_layout(B4)]).

-module(dynamiclayout).
-export([begin/1, end_layout/1, fieldset/2, end_fieldset/1]).
-export([label/2, alert/3, badge/3, spacer/1, spacer/2]).
-export([input/3, input/4, textarea/3, textarea/4, checkbox/2, checkbox/3, rating/2]).
-export([button/4, button/5, section/2, section/3]).

begin(Title) ->
    {B, _} = #{buf => <<"{\"ui\":{">>, depth => 2, comma => false, cnt => 0},
    B1 = kv(B, <<"title">>, Title),
    arr(B1, <<"layout">>),
    B1.

end_layout(B) ->
    B1 = close_arr(B),
    B2 = B1#{comma := false},
    B3 = putc(B2, $,),
    B4 = puts(B3, <<"\"translations\":{},">>),
    B5 = puts(B4, <<"\"userAccess\":{\"cancel\":true}">>),
    puts(B5, <<"}}">>),
    binary_to_list(B5).

%% -- internal --
putc(B = #{buf := Buf}, C) -> B#{buf := <<Buf/binary, C>>}.
puts(B = #{buf := Buf}, S) -> B#{buf := <<Buf/binary, S/binary>>}.
indent(B = #{depth := D}) ->
    B1 = putc(B, $\n),
    lists:foldl(fun(_, Acc) -> puts(Acc, <<"  ">>) end, B1, lists:seq(1, D)).
cm(B = #{comma := true}) -> putc(B#{comma := false}, $,);
cm(B) -> B.

esc(B, S) ->
    B1 = putc(B, $"),
    B2 = lists:foldl(fun
        ($",  Acc) -> puts(Acc, <<"\\\"">>);
        ($\\, Acc) -> puts(Acc, <<"\\\\">>);
        ($\n, Acc) -> puts(Acc, <<"\\n">>);
        ($\r, Acc) -> puts(Acc, <<"\\r">>);
        ($\t, Acc) -> puts(Acc, <<"\\t">>);
        (C,   Acc) -> putc(Acc, C)
    end, B1, binary_to_list(S)),
    putc(B2, $").

kv(B, K, V) ->
    B1 = cm(B), B2 = putc(B1, $,), B3 = indent(B2),
    B4 = esc(B3, K), B5 = puts(B4, <<": ">>), B6 = esc(B5, V),
    B6#{comma => true}.

kvint(B, K, V) ->
    B1 = cm(B), B2 = putc(B1, $,), B3 = indent(B2),
    B4 = esc(B3, K), B5 = puts(B4, <<": ">>),
    putc(B5#{comma => true}, integer_to_list(V)).

kvbool(B, K) ->
    B1 = cm(B), B2 = putc(B1, $,), B3 = indent(B2),
    B4 = esc(B3, K), puts(B4#{comma => true}, <<": true">>).

obj(B = #{depth := D}) ->
    B1 = cm(B), B2 = putc(B1, $,), B3 = indent(B2),
    putc(B3#{depth := D + 1, comma := false}, ${).

close_obj(B = #{depth := D}) ->
    B1 = B#{depth := D - 1, comma := false}, B2 = indent(B1),
    putc(B2#{comma := true}, $}).

arr(B = #{depth := D}, K) ->
    B1 = cm(B), B2 = putc(B1, $,), B3 = indent(B2),
    B4 = esc(B3, K), B5 = puts(B4, <<": [">>),
    B5#{depth := D + 1, comma := false}.

close_arr(B = #{depth := D}) ->
    B1 = B#{depth := D - 1, comma := false}, B2 = indent(B1),
    putc(B2#{comma := true}, $]).

key(B = #{cnt := C}, P) ->
    {B#{cnt := C + 1}, list_to_binary([P, "_", integer_to_list(C + 1)])}.

%% -- public --
fieldset(B, Title) ->
    {B1, K} = key(B, <<"fs">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"FIELDSET">>),
    B4 = kv(B3, <<"key">>, K), B5 = kv(B4, <<"title">>, Title),
    arr(B5, <<"content">>).

end_fieldset(B) -> close_obj(close_arr(B)).

label(B, Text) ->
    {B1, K} = key(B, <<"l">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"LABEL">>),
    B4 = kv(B3, <<"key">>, K), B5 = kv(B4, <<"label">>, Text),
    close_obj(B5).

alert(B, Msg, Color) ->
    {B1, K} = key(B, <<"a">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"ALERT">>),
    B4 = kv(B3, <<"key">>, K), B5 = kv(B4, <<"message">>, Msg),
    close_obj(kv(B5, <<"color">>, list_to_binary(Color))).

badge(B, Title, Color) ->
    {B1, K} = key(B, <<"bd">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"BADGE">>),
    B4 = kv(B3, <<"key">>, K), B5 = kv(B4, <<"title">>, Title),
    close_obj(kv(B5, <<"color">>, list_to_binary(Color))).

spacer(B) -> spacer(B, 20).
spacer(B, Px) ->
    {B1, K} = key(B, <<"sp">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"SPACER">>),
    close_obj(kvint(kv(B3, <<"key">>, K), <<"width">>, Px)).

input(B, Id, Label) -> input(B, Id, Label, false).
input(B, Id, Label, Req) ->
    {B1, K} = key(B, <<"i">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"INPUT">>),
    B4 = kv(B3, <<"key">>, K), B5 = kv(B4, <<"id">>, Id),
    B6 = kv(B5, <<"label">>, Label),
    close_obj(case Req of true -> kvbool(B6, <<"required">>); _ -> B6 end).

checkbox(B, Id) -> checkbox(B, Id, <<"">>).
checkbox(B, Id, Label) ->
    {B1, K} = key(B, <<"cb">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"CHECKBOX">>),
    close_obj(kv(kv(kv(B3, <<"key">>, K), <<"id">>, Id), <<"label">>, Label)).

textarea(B, Id, Label) -> textarea(B, Id, Label, 3).
textarea(B, Id, Label, Rows) ->
    {B1, K} = key(B, <<"ta">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"TEXTAREA">>),
    B4 = kv(B3, <<"key">>, K), B5 = kv(B4, <<"id">>, Id),
    close_obj(kvint(kv(B5, <<"label">>, Label), <<"rows">>, Rows)).

rating(B, Id) ->
    {B1, K} = key(B, <<"rt">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"RATING">>),
    close_obj(kv(kv(B3, <<"key">>, K), <<"id">>, Id)).

button(B, Id, Title, Color) -> button(B, Id, Title, Color, false).
button(B, Id, Title, Color, Def) ->
    {B1, K} = key(B, <<"btn">>),
    B2 = obj(B1), B3 = kv(B2, <<"type">>, <<"BUTTON">>),
    B4 = kv(B3, <<"key">>, K), B5 = kv(B4, <<"id">>, Id),
    B6 = kv(B5, <<"title">>, Title),
    B7 = kv(B6, <<"color">>, list_to_binary(Color)),
    close_obj(case Def of true -> kvbool(B7, <<"default">>); _ -> B7 end).

section(B, Title) -> section(B, Title, <<"">>).
section(B, Title, Text) ->
    B1 = fieldset(B, Title),
    B2 = label(B1, Text),
    end_fieldset(B2).
