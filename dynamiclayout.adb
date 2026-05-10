-- DynamicLayout Ada body — manual JSON generation

with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded.Text_IO;

package body DynamicLayout is

   procedure Put (B : in out DL_Builder; C : Character) is
   begin
      Append (B.Buffer, String'(1 => C));
   end Put;

   procedure Put_Str (B : in out DL_Builder; S : String) is
   begin
      Append (B.Buffer, S);
   end Put_Str;

   procedure Indent (B : in out DL_Builder) is
   begin
      Put (B, ASCII.LF);
      for I in 1 .. B.Depth loop
         Put_Str (B, "  ");
      end loop;
   end Indent;

   procedure Comma_Check (B : in out DL_Builder) is
   begin
      if B.Comma then
         Put (B, ',');
         B.Comma := False;
      end if;
   end Comma_Check;

   procedure Escape_String (B : in out DL_Builder; S : String) is
   begin
      Put (B, '"');
      for I in S'Range loop
         case S(I) is
            when '"'  => Put_Str (B, "\""");
            when '\'  => Put_Str (B, "\\");
            when ASCII.LF => Put_Str (B, "\n");
            when ASCII.CR => Put_Str (B, "\r");
            when ASCII.HT => Put_Str (B, "\t");
            when others => Put (B, S(I));
         end case;
      end loop;
      Put (B, '"');
   end Escape_String;

   procedure Key_Value (B : in out DL_Builder; Key, Val : String) is
   begin
      Comma_Check (B); Put (B, ','); Indent (B);
      Escape_String (B, Key); Put_Str (B, ": "); Escape_String (B, Val);
      B.Comma := True;
   end Key_Value;

   procedure Key_Value_Bool (B : in out DL_Builder; Key : String) is
   begin
      Comma_Check (B); Put (B, ','); Indent (B);
      Escape_String (B, Key); Put_Str (B, ": true");
      B.Comma := True;
   end Key_Value_Bool;

   procedure Key_Value_Int (B : in out DL_Builder; Key : String; Val : Integer) is
      S : constant String := Integer'Image (Val);
   begin
      Comma_Check (B); Put (B, ','); Indent (B);
      Escape_String (B, Key); Put_Str (B, ": "); Put_Str (B, Trim (S, Left));
      B.Comma := True;
   end Key_Value_Int;

   procedure Open_Obj (B : in out DL_Builder) is
   begin
      Comma_Check (B); Put (B, ','); Indent (B);
      Put (B, '{'); B.Depth := B.Depth + 1; B.Comma := False;
   end Open_Obj;

   procedure Close_Obj (B : in out DL_Builder) is
   begin
      B.Depth := B.Depth - 1; Indent (B); Put (B, '}'); B.Comma := True;
   end Close_Obj;

   procedure Open_Arr (B : in out DL_Builder; Key : String) is
   begin
      Comma_Check (B); Put (B, ','); Indent (B);
      Escape_String (B, Key); Put_Str (B, ": [");
      B.Depth := B.Depth + 1; B.Comma := False;
   end Open_Arr;

   procedure Close_Arr (B : in out DL_Builder) is
   begin
      B.Depth := B.Depth - 1; Indent (B); Put (B, ']'); B.Comma := True;
   end Close_Arr;

   function Next_Key (B : in out DL_Builder; Prefix : String) return String is
   begin
      B.Counter := B.Counter + 1;
      return Prefix & "_" & Trim (Integer'Image (B.Counter), Left);
   end Next_Key;

   -- ── Public API ──

   function Begin_Layout (Title : String) return DL_Builder is
      B : DL_Builder;
   begin
      Put_Str (B, "{\"" & "ui\":{");
      B.Depth := 2; B.Comma := False;
      Key_Value (B, "title", Title);
      Open_Arr (B, "layout");
      return B;
   end Begin_Layout;

   function End_Layout (B : DL_Builder) return String is
      Result : DL_Builder := B;
   begin
      Close_Arr (Result);
      Result.Comma := False; Put (Result, ',');
      Put_Str (Result, "\"" & "translations\":{},");
      Put_Str (Result, "\"" & "userAccess\":{\"cancel\":true}");
      Put_Str (Result, "}}");
      return To_String (Result.Buffer);
   end End_Layout;

   -- ── Containers ──

   procedure Fieldset (B : in out DL_Builder; Title : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "FIELDSET");
      Key_Value (B, "key", Next_Key (B, "fs"));
      Key_Value (B, "title", Title);
      Open_Arr (B, "content");
   end Fieldset;

   procedure Fieldset_Collapsed (B : in out DL_Builder; Title : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "FIELDSET");
      Key_Value (B, "key", Next_Key (B, "fs"));
      Key_Value (B, "title", Title);
      Key_Value_Bool (B, "collapsed");
      Open_Arr (B, "content");
   end Fieldset_Collapsed;

   procedure End_Fieldset (B : in out DL_Builder) is
   begin
      Close_Arr (B); Close_Obj (B);
   end End_Fieldset;

   procedure Row (B : in out DL_Builder) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "ROW");
      Key_Value (B, "key", Next_Key (B, "r"));
      Open_Arr (B, "content");
   end Row;

   procedure End_Row (B : in out DL_Builder) is
   begin
      Close_Arr (B); Close_Obj (B);
   end End_Row;

   procedure Col (B : in out DL_Builder; XS, MD : Integer) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "COL");
      Key_Value (B, "key", Next_Key (B, "c"));
      if XS /= 0 or MD /= 0 then
         Comma_Check (B); Put (B, ','); Indent (B);
         Put_Str (B, "\"" & "length\":{");
         if XS /= 0 then
            Put_Str (B, "\"" & "xs\":"); Key_Value_Int (B, "", XS);
            -- Wipe the comma just set by KV_Int since we're in the middle of a hand-built block
            Delete (B.Buffer, Length (B.Buffer) - 1, Length (B.Buffer));
            B.Comma := False;
         end if;
         if MD /= 0 then
            if XS /= 0 then Put (B, ','); end if;
            Put_Str (B, "\"" & "md\":");
            Key_Value_Int (B, "", MD);
            Delete (B.Buffer, Length (B.Buffer) - 1, Length (B.Buffer));
            B.Comma := False;
         end if;
         Put_Str (B, "}");
         B.Comma := True;
      end if;
      Open_Arr (B, "content");
   end Col;

   procedure End_Col (B : in out DL_Builder) is
   begin
      Close_Arr (B); Close_Obj (B);
   end End_Col;

   -- ── Display ──

   procedure Label (B : in out DL_Builder; Text : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "LABEL");
      Key_Value (B, "key", Next_Key (B, "l"));
      Key_Value (B, "label", Text);
      Close_Obj (B);
   end Label;

   procedure Alert (B : in out DL_Builder; Message, Color : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "ALERT");
      Key_Value (B, "key", Next_Key (B, "a"));
      Key_Value (B, "message", Message);
      Key_Value (B, "color", Color);
      Close_Obj (B);
   end Alert;

   procedure Badge (B : in out DL_Builder; Title, Color : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "BADGE");
      Key_Value (B, "key", Next_Key (B, "bd"));
      Key_Value (B, "title", Title);
      Key_Value (B, "color", Color);
      Close_Obj (B);
   end Badge;

   procedure Spacer (B : in out DL_Builder; Height_Px : Integer) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "SPACER");
      Key_Value (B, "key", Next_Key (B, "sp"));
      Key_Value_Int (B, "width", Height_Px);
      Close_Obj (B);
   end Spacer;

   procedure Progress (B : in out DL_Builder; Label_Text : String; Pct : Integer; Color : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "PROGRESS");
      Key_Value (B, "key", Next_Key (B, "pr"));
      if Label_Text'Length > 0 then Key_Value (B, "label", Label_Text); end if;
      Key_Value_Int (B, "progress", Pct);
      if Color'Length > 0 then Key_Value (B, "color", Color); end if;
      Close_Obj (B);
   end Progress;

   -- ── Inputs ──

   procedure Input_Field (B : in out DL_Builder; Id, Field_Label : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "INPUT");
      Key_Value (B, "key", Next_Key (B, "i"));
      Key_Value (B, "id", Id);
      Key_Value (B, "label", Field_Label);
      Close_Obj (B);
   end Input_Field;

   procedure Input_Required (B : in out DL_Builder; Id, Field_Label : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "INPUT");
      Key_Value (B, "key", Next_Key (B, "i"));
      Key_Value (B, "id", Id);
      Key_Value (B, "label", Field_Label);
      Key_Value_Bool (B, "required");
      Close_Obj (B);
   end Input_Required;

   procedure Textarea (B : in out DL_Builder; Id, Field_Label : String; Rows : Integer := 3) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "TEXTAREA");
      Key_Value (B, "key", Next_Key (B, "ta"));
      Key_Value (B, "id", Id);
      Key_Value (B, "label", Field_Label);
      if Rows > 0 then Key_Value_Int (B, "rows", Rows); end if;
      Close_Obj (B);
   end Textarea;

   procedure Checkbox (B : in out DL_Builder; Id, Field_Label : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "CHECKBOX");
      Key_Value (B, "key", Next_Key (B, "cb"));
      Key_Value (B, "id", Id);
      Key_Value (B, "label", Field_Label);
      Close_Obj (B);
   end Checkbox;

   procedure Select_Field (B : in out DL_Builder; Id, Field_Label : String; Ids, Labels : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "SELECT");
      Key_Value (B, "key", Next_Key (B, "s"));
      Key_Value (B, "id", Id);
      Key_Value (B, "label", Field_Label);
      -- For simplicity, accepting a note that select values need
      -- manual assembly in Ada; this stub shows the pattern
      Put_Str (B, ",");
      Indent (B);
      Put_Str (B, "\"values\": []");
      B.Comma := True;
      Close_Obj (B);
   end Select_Field;

   procedure Rating (B : in out DL_Builder; Id, Field_Label : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "RATING");
      Key_Value (B, "key", Next_Key (B, "rt"));
      Key_Value (B, "id", Id);
      Key_Value (B, "label", Field_Label);
      Close_Obj (B);
   end Rating;

   procedure Readonly_Field (B : in out DL_Builder; Id, Field_Label : String) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "READONLY_FIELD");
      Key_Value (B, "key", Next_Key (B, "ro"));
      Key_Value (B, "id", Id);
      Key_Value (B, "label", Field_Label);
      Close_Obj (B);
   end Readonly_Field;

   -- ── Actions ──

   procedure Button (B : in out DL_Builder; Id, Title, Color : String; Is_Default : Boolean := False) is
   begin
      Open_Obj (B);
      Key_Value (B, "type", "BUTTON");
      Key_Value (B, "key", Next_Key (B, "btn"));
      Key_Value (B, "id", Id);
      Key_Value (B, "title", Title);
      Key_Value (B, "color", Color);
      if Is_Default then Key_Value_Bool (B, "default"); end if;
      Close_Obj (B);
   end Button;

   -- ── Shortcuts ──

   procedure Section (B : in out DL_Builder; Title, Text : String) is
   begin
      Fieldset (B, Title);
      Label (B, Text);
      End_Fieldset (B);
   end Section;

   procedure Feedback_Form (B : in out DL_Builder) is
   begin
      Fieldset (B, "Your Details");
      Input_Required (B, "name", "Name");
      Input_Required (B, "email", "Email");
      Textarea (B, "message", "Message", 5);
      End_Fieldset (B);
      Button (B, "send", "Send", "primary", True);
      Button (B, "cancel", "Cancel", "secondary", False);
   end Feedback_Form;

end DynamicLayout;
