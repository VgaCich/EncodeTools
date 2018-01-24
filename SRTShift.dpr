program SSAShift;

{$APPTYPE CONSOLE}

uses
  AvL, avlUtils, avlMasks;

function SRTTimeToMS(SRT: string): Integer;
var
  H, M, S, MS: Integer;
begin
  SRT:=Trim(SRT);
  H:=StrToInt(Tok(':', SRT));
  M:=StrToInt(Tok(':', SRT));
  Delete(SRT, 1, 1);
  S:=StrToInt(Tok(',', SRT));
  Delete(SRT, 1, 1);
  if Length(SRT)>3 then SetLength(SRT, 3);
  while Length(SRT)<3 do SRT:=SRT+'0';
  MS:=StrToInt(SRT);
  Result:=3600000*H+60000*M+1000*S+MS;
end;

function MSToSRTTime(MS: Integer): string;
var
  H, M, S: Integer;
begin
  H:=MS div 3600000;
  MS:=MS mod 3600000;
  M:=MS div 60000;
  MS:=MS mod 60000;
  S:=MS div 1000;
  MS:=MS mod 1000;
  Result:=IntToStrLZ(H, 2)+':'+IntToStrLZ(M, 2)+':'+IntToStrLZ(S, 2)+','+IntToStrLZ(MS, 3);
end;

function ShowTime(MS: Integer): string;
begin
  case MS of
    -MaxInt: Result:='beginning';
    MaxInt: Result:='end';
    else Result:=MSToSRTTime(MS);
  end;
end;

var
  Script: TStringList;
  i, P1, Shift, Time, Count: Integer;
  FromTime: Integer = -MaxInt;
  ToTime: Integer = MaxInt;
  S, S1, S2: string;
  Mask: TMask;

begin
  WriteLn('SRTShift 1.0 by Vga');
  if ParamCount<2 then
  begin
    WriteLn('Usage:');
    WriteLn('SRTShift <SRT file> <shift in ms> [-f<from>] [-t<to>]');
    Exit;
  end;
  if not FileExists(ParamStr(1)) then
  begin
    WriteLn('File "'+ParamStr(1)+'" not found.');
    Exit;
  end;
  Shift:=StrToInt(ParamStr(2));
  for i:=3 to ParamCount do
  begin
    S:=ParamStr(i);
    if (Length(S)>=2) and (S[1]='-') then
      case UpCase(S[2]) of
        'F': FromTime:=SRTTimeToMS(Copy(S, 3, MaxInt));
        'T': ToTime:=SRTTimeToMS(Copy(S, 3, MaxInt));
        else WriteLn('Unknown parameter: ', S);
      end;
  end;
  WriteLn('Shifting "'+ParamStr(1)+'" by '+IntToStr(Shift)+'.');
  WriteLn('Limits: from '+ShowTime(FromTime)+' to '+ShowTime(ToTime)+'.');
  Count:=0;
  Mask:=TMask.Create('??:??:??,??? --> ??:??:??,???');
  Script:=TStringList.Create;
  Script.LoadFromFile(ParamStr(1));
  try
    for i:=0 to Script.Count-1 do
    begin
      S:=Script[i];
      if Mask.Matches(S) then
      begin
        P1:=Pos('-->', S)-1;
        S1:=Trim(Copy(S, 1, P1));
        Time:=SRTTimeToMS(S1);
        if (Time<FromTime) or (Time>ToTime) then Continue;
        S2:=Trim(Copy(S, P1+4, MaxInt));
        Script[i]:=MSToSRTTime(Max(0, Time+Shift))+' --> '+MSToSRTTime(Max(0, SRTTimeToMS(S2)+Shift));
        Inc(Count);
      end;
    end;
    Script.SaveToFile(ParamStr(1));
    WriteLn('Done. '+IntToStr(Count)+' lines processed.');
  finally
    FAN(Script);
    FAN(Mask);
  end;
end.