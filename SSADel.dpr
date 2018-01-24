program SSADel;

{$APPTYPE CONSOLE}

uses
  AvL, avlUtils, avlMasks;

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
  Mask: TMask;
  i, Nfield, Field, Time, Count: Integer;
  FromTime: Integer = -MaxInt;
  ToTime: Integer = MaxInt;
  S, T, Time1: string;
  Match: Boolean;

begin
  WriteLn('SSADel 1.0 by Vga');
  if ParamCount<2 then
  begin
    WriteLn('Usage:');
    WriteLn('SSADel <SSA file> <Nfield:mask> [-f<from>] [-t<to>]');
    Exit;
  end;
  if not FileExists(ParamStr(1)) then
  begin
    WriteLn('File "'+ParamStr(1)+'" not found.');
    Exit;
  end;
  Nfield:=StrToInt(Copy(ParamStr(2), 1, FirstDelimiter(':', ParamStr(2))-1));
  Mask:=TMask.Create(Copy(ParamStr(2), FirstDelimiter(':', ParamStr(2))+1, MaxInt));
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
  WriteLn('Deleting: "'+Copy(ParamStr(2), FirstDelimiter(':', ParamStr(2))+1, MaxInt)+'" at field '+IntToStr(Nfield)+' from "'+ParamStr(1)+'".');
  WriteLn('Limits: from '+ShowTime(FromTime)+' to '+ShowTime(ToTime)+'.');
  Count:=0;
  Script:=TStringList.Create;
  Script.LoadFromFile(ParamStr(1));
  try
    i:=-1;
    while i<Script.Count do
    begin
      Inc(i);
      S:=Script[i];
      if UpperCase(Copy(Trim(S), 1, 9))='DIALOGUE:' then
      begin
        S:=Trim(Copy(Trim(S), 10, MaxInt));
        Field:=1;
        Match:=false;
        while S<>'' do
        begin
          T:=Tok(',', S);
          if Field=2 then Time1:=T;
          if (Field=Nfield) and Mask.Matches(T) then Match:=true;
          if Field>=Max(Nfield, 2) then Break;
          Inc(Field);
        end;
        Time:=SSATimeToMS(Time1);
        if (Time<FromTime) or (Time>ToTime) or not Match then Continue;
        Script.Delete(i);
        Dec(i);
        Inc(Count);
      end;
    end;
    Script.SaveToFile(ParamStr(1));
    WriteLn('Done. '+IntToStr(Count)+' lines processed.');
  finally
    FAN(Script);
  end;
end.