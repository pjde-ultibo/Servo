unit uServos;

{$mode objfpc}{$H+}

(* This unit is mostly based on the web page :-
  Pi Servo Hat Hookup Guide
     https://learn.sparkfun.com/tutorials/pi-servo-hat-hookup-guide

  PJde 2019
*)

interface

uses
  Classes, SysUtils, i2c;

const
  DEF_I2C_ADDR                    = $40;

  // Register addresses from data sheet
  MODE1_REG                       = $00;
  MODE2_REG                       = $01;
  SUBADR1_REG                     = $02;
  SUBADR2_REG                     = $03;
  SUBADR3_REG                     = $04;
  ALLCALL_REG                     = $05;
  LED0_REG                        = $06; // Start of LEDx regs, 4B per reg, 2B on phase, 2B off phase, little-endian
  PRESCALE_REG                    = $FE;
  ALLLED_REG                      = $FA;

  // Mode1 register bit layout
  MODE_RESTART                    = $80;
  MODE_EXTCLK                     = $40;
  MODE_AUTOINC                    = $20;
  MODE_SLEEP                      = $10;
  MODE_SUBADR1                    = $08;
  MODE_SUBADR2                    = $04;
  MODE_SUBADR3                    = $02;
  MODE_ALLCALL                    = $01;

  SW_RESET                        = $06;    // Sent to address 0x00 to reset device
  PWM_FULL                        = $1000;  // Special value for full on/full off LEDx modes

type

  { TServoHAT }

  TServoHAT = class
  private
    FAddr : byte;
    function ReadRegister (Reg : byte) : byte;
    procedure WriteRegister (Reg, Data : byte);
  public
    procedure SetPWMFreq (freq : integer);
    function GetPWMFreq : integer;
    function ReadChannel (Chan : byte) : Word;
    procedure WriteChannel (Chan : Byte; Data : Word);
    constructor Create (Addr : byte);
    destructor Destroy; override;
  end;

implementation

uses
  GlobalConst, uLog;

{ TServoHAT }

function TServoHAT.ReadRegister (Reg : byte): byte;
var
  Data : byte;
  Count : LongWord;
begin
  Result := 0;
  Count := 0;
  if SysI2CWriteRead (FAddr, @Reg, 1, @Data, 1, Count) = ERROR_SUCCESS then
    Result := Data
  else
    Log ('Read Register ' + Reg.ToHexString(2) + ' Failed.');
end;

procedure TServoHAT.WriteRegister (Reg, Data : byte);
var
  Count : LongWord;
begin
  Count := 0;
  if SysI2CwriteWrite (FAddr, @Reg, 1, @Data, 1, Count) <> ERROR_SUCCESS then
    Log ('Write Register ' + Reg.ToHexString(2) + ' Failed.');
end;

function TServoHAT.ReadChannel (Chan : byte) : Word;
var
  Count : LongWord;
  Reg : byte;
  Val : array [0..3] of byte;
  i : integer;
begin
  Result := 0;
  if Chan > 15 then exit;
  Reg := (Chan * 4) + LED0_REG;
  Count := 0;
  if SysI2CWriteRead (FAddr, @Reg, 1, @Val, 4, Count) = ERROR_SUCCESS then
    Result := Val[2] + Val[3] * $100
  else
   Log ('Write Channel ' + Chan.ToString + ' Failed.')
end;

procedure TServoHAT.WriteChannel (Chan : Byte; Data : Word);
var
  Count : LongWord;
  Val : array [0..3] of byte;
  Reg : byte;
  i : integer;
begin
  if Chan > 15 then exit;
  Reg := (Chan * 4) + LED0_REG;
  Count := 0;
  Val[0] := 0;
  Val[1] := 0;
  Val[2] := Lo (Data);
  Val[3] := Hi (Data);
  if SysI2CWriteWrite (FAddr, @Reg, 1, @Val, 4, Count) <> ERROR_SUCCESS then
    Log ('Write Channel ' + Chan.ToString + ' Failed.');
end;

procedure TServoHAT.SetPWMFreq (freq : integer);
var
  PreScaler : integer;
  Data : byte;
begin
  PreScaler := (25000000 div (4096 * freq)) - 1;   //  Lowest freq is 23.84, highest is 1525.88.
  if PreScaler > 255 then PreScaler := 255;
  if PreScaler < 3 then PreScaler := 3;
  // The PRE_SCALE register can only be set when the SLEEP bit of MODE1 register is set.
  Data := ReadRegister (MODE1_REG);
  Data := Data and (not MODE_RESTART) or MODE_SLEEP;
  WriteRegister (MODE1_REG, Data);
  WriteRegister (PRESCALE_REG, PreScaler);
  Data := Data and (not MODE_SLEEP) or MODE_RESTART;
  WriteRegister (MODE1_REG, Data);
  // It takes 500us max for the oscillator to be up and running once SLEEP bit has been reset.
  sleep (500);
end;

function TServoHAT.GetPWMFreq : integer;
var
  Data : byte;
begin
  Data := ReadRegister (PRESCALE_REG);
  Result := (25000000 div (Data + 1)) div 4096;
end;

constructor TServoHAT.Create (Addr : byte);
var
  res : LongWord;
begin
  FAddr := Addr;
  res := SysI2CStart (100000);
  if res = ERROR_SUCCESS then
    begin
      WriteRegister (MODE1_REG, MODE_RESTART or MODE_AUTOINC);
    end
  else
    Log ('Error Starting I2C.');
end;

destructor TServoHAT.Destroy;
begin
  inherited;
end;


end.

