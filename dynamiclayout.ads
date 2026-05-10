-- DynamicLayout Ada API — generate layout JSON from Ada code.
--
-- Single-file spec (spec only for simplicity; body integrated below).
-- Zero dependencies outside the Ada standard library.
-- Works on GNAT 12+.
--
-- Example:
--   with DynamicLayout; use DynamicLayout;
--   ...
--   B : DL_Builder := Begin ("My Page");
--   Fieldset (B, "Info");
--   Label (B, "Hello from Ada!");
--   End_Fieldset (B);
--   Button (B, "ok", "OK", "primary", True);
--   Put_Line (End_Layout (B));

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package DynamicLayout is

   type DL_Builder is private;

   -- Initialize and finalize
   function Begin_Layout (Title : String) return DL_Builder;
   function End_Layout (B : DL_Builder) return String;

   -- Containers
   procedure Fieldset (B : in out DL_Builder; Title : String);
   procedure Fieldset_Collapsed (B : in out DL_Builder; Title : String);
   procedure End_Fieldset (B : in out DL_Builder);
   procedure Row (B : in out DL_Builder);
   procedure End_Row (B : in out DL_Builder);
   procedure Col (B : in out DL_Builder; XS, MD : Integer);
   procedure End_Col (B : in out DL_Builder);

   -- Display
   procedure Label (B : in out DL_Builder; Text : String);
   procedure Alert (B : in out DL_Builder; Message, Color : String);
   procedure Badge (B : in out DL_Builder; Title, Color : String);
   procedure Spacer (B : in out DL_Builder; Height_Px : Integer);
   procedure Progress (B : in out DL_Builder; Label_Text : String; Pct : Integer; Color : String);

   -- Inputs
   procedure Input_Field (B : in out DL_Builder; Id, Field_Label : String);
   procedure Input_Required (B : in out DL_Builder; Id, Field_Label : String);
   procedure Textarea (B : in out DL_Builder; Id, Field_Label : String; Rows : Integer := 3);
   procedure Checkbox (B : in out DL_Builder; Id, Field_Label : String);
   procedure Select_Field (B : in out DL_Builder; Id, Field_Label : String; Ids, Labels : String);
   procedure Rating (B : in out DL_Builder; Id, Field_Label : String);
   procedure Readonly_Field (B : in out DL_Builder; Id, Field_Label : String);

   -- Actions
   procedure Button (B : in out DL_Builder; Id, Title, Color : String; Is_Default : Boolean := False);

   -- Shortcuts
   procedure Section (B : in out DL_Builder; Title, Text : String);
   procedure Feedback_Form (B : in out DL_Builder);

private

   type DL_Builder is record
      Buffer  : Unbounded_String;
      Depth   : Integer := 0;
      Comma   : Boolean := False;
      Counter : Integer := 0;
   end record;

   procedure Put (B : in out DL_Builder; C : Character);
   procedure Put_Str (B : in out DL_Builder; S : String);
   procedure Indent (B : in out DL_Builder);
   procedure Comma_Check (B : in out DL_Builder);
   procedure Escape_String (B : in out DL_Builder; S : String);
   procedure Key_Value (B : in out DL_Builder; Key, Val : String);
   procedure Key_Value_Bool (B : in out DL_Builder; Key : String);
   procedure Key_Value_Int (B : in out DL_Builder; Key : String; Val : Integer);
   procedure Open_Obj (B : in out DL_Builder);
   procedure Close_Obj (B : in out DL_Builder);
   procedure Open_Arr (B : in out DL_Builder; Key : String);
   procedure Close_Arr (B : in out DL_Builder);
   function  Next_Key (B : in out DL_Builder; Prefix : String) return String;

end DynamicLayout;
