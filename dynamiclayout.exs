# DynamicLayout Elixir API — generate layout JSON from Elixir code.
#
# Single-file module. Zero dependencies outside stdlib.
# Works on Elixir 1.14+.
#
# Example:
#   alias DynamicLayout, as: DL
#   DL.begin("My Page")
#   |> DL.fieldset("Info")
#   |> DL.label("Hello from Elixir!")
#   |> DL.end_fieldset()
#   |> DL.button("ok", "OK", "primary", true)
#   |> DL.end_layout()
#   |> IO.puts()

defmodule DynamicLayout do
  defstruct buf: "", depth: 0, comma: false, cnt: 0

  def begin(title) do
    %__MODULE__{}
    |> puts(~s({"ui":{))
    |> struct!(depth: 2, comma: false)
    |> kv("title", title)
    |> arr("layout")
  end

  # internal
  defp putc(b, c), do: %{b | buf: b.buf <> <<c>>}
  defp puts(b, s), do: %{b | buf: b.buf <> s}
  defp indent(b), do: b |> putc(?\n) |> puts(String.duplicate("  ", b.depth))
  defp cm(b), do: if(b.comma, do: putc(%{b | comma: false}, ?,), else: b)
  defp esc(b, s) do
    b |> putc(?") |> puts(s |> String.replace("\\", "\\\\") |> String.replace("\"", "\\\"") |> String.replace("\n", "\\n")) |> putc(?")
  end
  defp kv(b, k, v) do
    b |> cm() |> putc(?,) |> indent() |> esc(k) |> puts(": ") |> esc(v) |> Map.put(:comma, true)
  end
  defp kvint(b, k, v) do
    b |> cm() |> putc(?,) |> indent() |> esc(k) |> puts(": #{v}") |> Map.put(:comma, true)
  end
  defp kvbool(b, k) do
    b |> cm() |> putc(?,) |> indent() |> esc(k) |> puts(": true") |> Map.put(:comma, true)
  end
  defp obj(b), do: b |> cm() |> putc(?,) |> indent() |> putc(?{) |> Map.merge(%{depth: b.depth + 1, comma: false})
  defp close_obj(b), do: %{b | depth: b.depth - 1} |> indent() |> putc(?}) |> Map.put(:comma, true)
  defp arr(b, k), do: b |> cm() |> putc(?,) |> indent() |> esc(k) |> puts(": [") |> Map.merge(%{depth: b.depth + 1, comma: false})
  defp close_arr(b), do: %{b | depth: b.depth - 1} |> indent() |> putc(?]) |> Map.put(:comma, true)
  defp key(b, p), do: {%{b | cnt: b.cnt + 1}, "#{p}_#{b.cnt + 1}"}

  def end_layout(b) do
    b |> close_arr() |> Map.put(:comma, false) |> putc(?,) |> puts(~s("translations":{},)) |> puts(~s("userAccess":{"cancel":true})) |> puts("}}") |> Map.get(:buf)
  end

  def fieldset(b, title) do
    {b, k} = key(b, "fs")
    b |> obj() |> kv("type", "FIELDSET") |> kv("key", k) |> kv("title", title) |> arr("content")
  end
  def end_fieldset(b), do: b |> close_arr() |> close_obj()

  def label(b, text) do
    {b, k} = key(b, "l")
    b |> obj() |> kv("type", "LABEL") |> kv("key", k) |> kv("label", text) |> close_obj()
  end
  def alert(b, msg, color \\ "info") do
    {b, k} = key(b, "a")
    b |> obj() |> kv("type", "ALERT") |> kv("key", k) |> kv("message", msg) |> kv("color", color) |> close_obj()
  end
  def badge(b, title, color \\ "primary") do
    {b, k} = key(b, "bd")
    b |> obj() |> kv("type", "BADGE") |> kv("key", k) |> kv("title", title) |> kv("color", color) |> close_obj()
  end
  def spacer(b, px \\ 20) do
    {b, k} = key(b, "sp")
    b |> obj() |> kv("type", "SPACER") |> kv("key", k) |> kvint("width", px) |> close_obj()
  end
  def input(b, id, label, required \\ false) do
    {b, k} = key(b, "i")
    b = b |> obj() |> kv("type", "INPUT") |> kv("key", k) |> kv("id", id) |> kv("label", label)
    b = if required, do: kvbool(b, "required"), else: b
    close_obj(b)
  end
  def checkbox(b, id, label \\ "") do
    {b, k} = key(b, "cb")
    b |> obj() |> kv("type", "CHECKBOX") |> kv("key", k) |> kv("id", id) |> kv("label", label) |> close_obj()
  end
  def textarea(b, id, label, rows \\ 3) do
    {b, k} = key(b, "ta")
    b = b |> obj() |> kv("type", "TEXTAREA") |> kv("key", k) |> kv("id", id) |> kv("label", label)
    b = if rows > 0, do: kvint(b, "rows", rows), else: b
    close_obj(b)
  end
  def rating(b, id, label \\ "") do
    {b, k} = key(b, "rt")
    b |> obj() |> kv("type", "RATING") |> kv("key", k) |> kv("id", id) |> kv("label", label) |> close_obj()
  end
  def button(b, id, title, color \\ "primary", is_default \\ false) do
    {b, k} = key(b, "btn")
    b = b |> obj() |> kv("type", "BUTTON") |> kv("key", k) |> kv("id", id) |> kv("title", title) |> kv("color", color)
    b = if is_default, do: kvbool(b, "default"), else: b
    close_obj(b)
  end
  def section(b, title, text) do
    b |> fieldset(title) |> label(text) |> end_fieldset()
  end
end
