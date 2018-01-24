program SSAShift;

{$APPTYPE CONSOLE}

uses
  AvL, avlUtils;

function SSATimeToMS(SSA: string): Integer;
var
  H, M, S, MS: Integer;
begin
  SSA:=Trim(SSA);
  H:=StrToInt(Tok(':', SSA));
  M:=StrToInt(Tok(':', SSA));
  Delete(SSA, 1, 1);
  S:=StrToInt(Tok('.', SSA));
  Delete(SSA, 1, 1);
  if Length(SSA)>3 then SetLength(SSA, 3);
  while Length(SSA)<3 do SSA:=SSA+'0';
  MS:=StrToInt(SSA);
  Result:=3600000*H+60000*M+1000*S+MS;
end;

function MSToSSATime(MS: Integer): string;
var
  H, M, S: Integer;
begin
  H:=MS div 3600000;
  MS:=MS mod 3600000;
  M:=MS div 60000;
  MS:=MS mod 60000;
  S:=MS div 1000;
  MS:=MS mod 1000;
  Result:=IntToStr(H)+':'+IntToStrLZ(M, 2)+':'+IntToStrLZ(S, 2)+'.'+IntToStrLZ(MS, 3);
  SetLength(Result, Length(Result)-1);
end;

function ShowTime(MS: Integer): string;
begin
  case MS of
    -MaxInt: Result:='beginning';
    MaxInt: Result:='end';
    else Result:=MSToSSATime(MS);
  end;
end;

var
  Script: TStringList;
  i, P1, P2, P3, Shift, Time, Count: Integer;
  FromTime: Integer = -MaxInt;
  ToTime: Integer = MaxInt;
  S, S1, S2: string;

begin
  WriteLn('SSAShift 1.0 by Vga');
  if ParamCount<2 then
  begin
    WriteLn('Usage:');
    WriteLn('SSAShift <SSA file> <shift in ms> [-f<from>] [-t<to>]');
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
        'F': FromTime:=SSATimeToMS(Copy(S, 3, MaxInt));
        'T': ToTime:=SSATimeToMS(Copy(S, 3, MaxInt));
        else WriteLn('Unknown parameter: ', S);
      end;
  end;
  WriteLn('Shifting "'+ParamStr(1)+'" by '+IntToStr(Shift)+'.');
  WriteLn('Limits: from '+ShowTime(FromTime)+' to '+ShowTime(ToTime)+'.');
  Count:=0;
  Script:=TStringList.Create;
  Script.LoadFromFile(ParamStr(1));
  try
    for i:=0 to Script.Count-1 do
    begin
      S:=Script[i];
      if UpperCase(Copy(Trim(S), 1, 9))='DIALOGUE:' then
      begin
        P1:=Pos(',', S)+1;
        P2:=PosEx(',', S, P1)+1;
        P3:=PosEx(',', S, P2)+1;
        S1:=Copy(S, P1, P2-P1-1);
        Time:=SSATimeToMS(S1);
        if (Time<FromTime) or (Time>ToTime) then Continue;
        S2:=Copy(S, P2, P3-P2-1);
        S1:=MSToSSATime(Max(0, Time+Shift));
        S2:=MSToSSATime(Max(0, SSATimeToMS(S2)+Shift));
        Script[i]:=Copy(S, 1, P1-1)+S1+','+S2+Copy(S, P3-1, MaxInt);
        Inc(Count);
      end;
    end;
    Script.SaveToFile(ParamStr(1));
    WriteLn('Done. '+IntToStr(Count)+' lines processed.');
  finally
    FAN(Script);
  end;
end.