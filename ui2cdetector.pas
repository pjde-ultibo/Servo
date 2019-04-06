unit uI2CDetector;

{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils, GlobalTypes, i2c;

procedure I2CDetect (Console : TWindowHandle);

implementation

uses
  GlobalConst, Console;

const
  COLOR_NAVY = $FF000080;

procedure I2CDetect (Console : TWindowHandle);
var
  Addr : Word;
  Count, fg, bg, ln : LongWord;
  Reg, Data : byte;
  f : boolean;
  s : string;
begin
  fg := ConsoleWindowGetForecolor (Console);
  bg := ConsoleWindowGetBackcolor (Console);
  if SysI2CStart (100000) <> ERROR_SUCCESS then
    ConsoleWindowWriteEx (Console, 'Can'' Start I2C...', 1, 1, COLOR_RED, bg)
  else
    begin
      s := '';
      ln := 0;
      ConsoleWindowWriteEx (Console, '    x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 xA xB xC xD xE xF', 1, 1, COLOR_NAVY, bg);
      for Addr := $00 to $7f do
        begin
          if Addr mod 16 = 0 then
            begin
              if length (s) > 0 then
                begin
                  ConsoleWindowWriteEx (Console, (ln - 1).ToHexString (1) + 'x:', 1, ln + 1, COLOR_NAVY, bg);
                  ConsoleWindowWriteEx (Console, s, 4, ln + 1, fg, bg);
                end;
              s := '';
              ln := ln + 1;
            end;
          if Addr = 0 then
            f := false
          else
            begin
              Count := 0;
              Reg := 0;
              f := SysI2CWriteRead (Addr, @Reg, 1, @Data, 1, Count) = ERROR_SUCCESS;
            end;
          if f then
            s := s + ' ' + Addr.ToHexString (2)
          else
            s := s + ' --';
        end;
      if length (s) > 0 then
        begin
          ConsoleWindowWriteEx (Console, (ln - 1).ToHexString (1) + 'x:', 1, ln + 1, COLOR_NAVY, bg);
          ConsoleWindowWriteEx (Console, s, 4, ln + 1, fg, bg);
        end;
    end;
//  SysI2CStop;
end;

end.

