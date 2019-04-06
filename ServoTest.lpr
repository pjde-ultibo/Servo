program ServoTest;

{$mode objfpc}{$H+}
{$define use_tftp}
{$hints off}
{$notes off}

{

  Test program for Sparkfun Pi Servo Shield.
  Tested using Duratech Micro Servo Motors (YM2758)

  PJde 2019
}

uses
  RaspberryPi3,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Console,
  Ultibo,
{$ifdef use_tftp}
  uTFTP, Winsock2,
{$endif}
  uServos, Logging, Services, uLog, uI2CDetector
  { Add additional units here };

var
  Console1, Console2, Console3 : TWindowHandle;
  ch : char;
  IPAddress : string;
  ServoHAT : TServoHAT;
  SysLogger : PLoggingDevice;

procedure Log1 (s : string);
begin
  ConsoleWindowWriteLn (Console1, s);
end;

procedure Log2 (s : string);
begin
  ConsoleWindowWriteLn (Console2, s);
end;

procedure Log3 (s : string);
begin
  ConsoleWindowWriteLn (Console3, s);
end;

procedure Msg2 (Sender : TObject; s : string);
begin
  Log2 ('TFTP - ' + s);
end;

procedure WaitForSDDrive;
begin
  while not DirectoryExists ('C:\') do sleep (500);
end;

function WaitForIPComplete : string;
var
  TCP : TWinsock2TCPClient;
begin
  TCP := TWinsock2TCPClient.Create;
  Result := TCP.LocalAddress;
  if (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') then
    begin
      while (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') do
        begin
          sleep (1000);
          Result := TCP.LocalAddress;
        end;
    end;
  TCP.Free;
end;

begin
  Console1 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_LEFT, true);
  Console2 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_TOPRIGHT, false);
  Console3 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_BOTTOMRIGHT, false);
  Log1 ('Pi servo Shield Test - For Servo HATs utilising the PCA9685 LED Controller.');
  WaitForSDDrive;
  Log1 ('SD Drive ready.');
  IPAddress := WaitForIPComplete;
  SetLogProc (@Log1);
{$ifdef use_tftp}
  Log2 ('TFTP - Syntax "tftp -i ' + IPAddress + ' put kernel7.img"');
  SetOnMsg (@Msg2);
  Log2 ('');
{$endif}
  SysLogger := LoggingDeviceFindByType (LOGGING_TYPE_SYSLOG);
  SysLogLoggingSetTarget (SysLogger, '10.0.0.4');
  LoggingDeviceSetDefault (SysLogger);
  ServoHAT := TServoHAT.Create (uServos.DEF_I2C_ADDR);
  ch := #0;
  while true do
    begin
      if ConsoleGetKey (ch, nil) then
        case (ch) of
          '1' : ServoHAT.SetPWMFreq (50);
          '2' : i2cDetect (Console3);
          '3' : Log ('PWN Frequency ' + ServoHat.GetPWMFreq.ToString);
          '4' : ServoHAT.WriteChannel (0, 100);
          '5' : ServoHAT.WriteChannel (0, 200);
          '6' : ServoHAT.WriteChannel (0, 300);
          '7' : ServoHAT.WriteChannel (0, 400);
          '8' : ServoHAT.WriteChannel (0, 500);
          '9' : ServoHAT.WriteChannel (0, 600);

          'A', 'a' : ServoHAT.WriteChannel (1, 100);
          'B', 'b' : ServoHAT.WriteChannel (1, 200);
          'C', 'c' : ServoHAT.WriteChannel (1, 400);
          'D', 'd' : ServoHAT.WriteChannel (1, 600);

          '0' : Log (ServoHat.ReadChannel (0).ToString);
          #27 : ConsoleWindowClear (Console1);
          end;
    end;
end.

