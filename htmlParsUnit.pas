unit htmlParsUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Buttons;

type
  THTMLParam = class
  private
    fRaw: string;
    fKey: string;
    fValue: string;
    procedure SetKey(Key:string);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Key: string read fKey write SetKey;
    property Value: string read fValue;
    property Raw: string read fRaw;
  end;

  THTMLTag = class
  private
    fName: string;
    fRaw: string;
    procedure SetName(Name: string);
  public
    Params: TList;
    constructor Create;
    destructor Destroy; override;
  published
    property Name: string read fName write SetName;
    property Raw: string read fRaw;
  end;

  THTMLText = class
  private
    fLine: string;
    fRawLine: string;
    procedure SetLine(Line: string);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Line: string read fLine write SetLine;
    property Raw: string read fRawLine;
  end;

  THTMLParser = class(TObject)
  private
    Text: string;
    Tag: string;
    isTag: boolean;
    procedure AddText;
    procedure AddTag;
  public
    Parsed: TList;
    Lines: TStringlist;
    constructor Create;
    destructor Destroy; override;
    procedure Execute;
    procedure Clear;
  published
  end;

implementation

constructor THTMLParser.Create;
begin
  inherited Create;
  Lines:=TStringlist.Create;
  Parsed:=TList.Create
end;

destructor THTMLParser.Destroy;
begin
  Lines.Free;
  Parsed.Free;
  inherited Destroy
end;

procedure THTMLParser.AddText;
var
  HTMLText: THTMLText;

begin
  if not isTag then
    if Text<>'' then
      begin
        HTMLText:=THTMLText.Create;
        HTMLText.Line:=Text;
        Text:='';
        Parsed.Add(HTMLText)
      end
end;

procedure THTMLParser.AddTag;
var
  HTMLTag: THTMLTag;

begin
  isTag:=false;
  HTMLTag:=THTMLTag.Create;
  HTMLTag.Name:=Tag;
  Tag:='';
  Parsed.Add(HTMLTag)
end;

procedure THTMLParser.Execute;
var
  i: integer;
  s: string;

begin
  Text:=''; Tag:='';
  isTag:=false;
  for i:=1 to Lines.Count do
    begin
      s:=Lines[i-1];
      while length(s) > 0 do
        begin
          if s[1]='<' then
            begin
              AddText; isTag:=true
            end
          else
            if s[1]='>' then AddTag
            else
              if isTag then Tag:=Tag+s[1]
              else
                Text:=Text+s[1];
          delete(s,1,1)
        end;
      if (not isTag) and (Text<>'') then Text:=Text+#10
    end;
  if (isTag) and (Tag<>'') then AddTag;
  if (not isTag) and (Text<>'') then AddText
end;

procedure THTMLParser.Clear;
var
  i: integer;
  obj: TObject;
begin
  for i:=Parsed.Count downto 1 do
    begin
      obj:=Parsed[i-1];
      if obj.ClassType = THTMLTag then
        THTMLTag(Parsed[i-1]).Free
      else
        if obj.ClassType = THTMLText then
          THTMLText(Parsed[i-1]).Free;
      Parsed.Delete(i-1)
    end
end;

constructor THTMLTag.Create;
begin
  inherited Create;
  Params:=Tlist.Create
end;

destructor THTMLTag.Destroy;
var
  i: integer;
begin
  for i:=Params.Count downto 1 do
    begin
      THTMLparam(Params[i-1]).Free;
      Params.delete(i-1)
    end;
  Params.Free;
  inherited Destroy
end;

procedure THTMLTag.SetName(Name: string);
var
  Tag: string;
  Param: string;
  HTMLParam: THTMLParam;
  iosQuote: boolean;

begin
  fRaw:=Name;
  Params.clear;
  while (Length(Name)>0) and (Name[1]<>' ') do
    begin
      Tag:=Tag+Name[1];
      delete(Name,1,1)
    end;
  fName:=uppercase(Tag);
  while (length(Name)>0) do
    begin
      param:='';
      iosQuote:=false;
      while (Length(Name)>0) and ( not ((Name[1]=' ') and (iosQuote=false))) do
        begin
          if Name[1]='"' then
            iosQuote:=not(iosQuote);
          Param:=param+Name[1];
          delete(Name,1,1)
        end;
      if (Length(Name)>0) and (Name[1]=' ') then Delete(Name,1,1);
      if param<>'' then
        begin
          HTMLParam:=THTMLParam.Create;
          HTMLParam.key:=param;
          Params.add(HTMLParam)
        end
    end
end;

const Entities:array [1..100,1..2] of string=(('&quot;',  '&#34;'), ('&amp;',   '&#38;'), ('&lt;',    '&#60;'),
															 ('&gt;',    '&#62;'), ('&nbsp;',  '&#160;'),('&iexcl;', '&#161;'),
                                              ('&cent;',  '&#162;'),('&pound;', '&#163;'),('&curren;','&#164;'),
                                              ('&yen;',   '&#165;'),('&brvbar;','&#166;'),('&sect;',  '&#167;'),
                                              ('&uml;',   '&#168;'),('&copy;',  '&#169;'),('&ordf;',  '&#170;'),
                                              ('&laquo;', '&#171;'),('&not;',   '&#172;'),('&shy;',   '&#173;'),
                                              ('&reg;',   '&#174;'),('&macr;',  '&#175;'),('&deg;',   '&#176;'),
                                              ('&plusmn;','&#177;'),('&sup2;',  '&#178;'),('&sup3;',  '&#179;'),
                                              ('&acute;', '&#180;'),('&micro;', '&#181;'),('&para;',  '&#182;'),
                                              ('&middot;','&#183;'),('&cedil;', '&#184;'),('&sup1;',  '&#185;'),
                                              ('&ordm;',  '&#186;'),('&raquo;', '&#187;'),('&frac14;','&#188;'),
                                              ('&frac12;','&#189;'),('&frac34;','&#190;'),('&iquest;','&#191;'),
                                              ('&Agrave;','&#192;'),('&Aacute;','&#193;'),('&Acirc;', '&#194;'),
                                              ('&Atilde;','&#195;'),('&Auml;',  '&#196;'),('&Aring;', '&#197;'),
                                              ('&AElig;', '&#198;'),('&Ccedil;','&#199;'),('&Egrave;','&#200;'),
                                              ('&Eacute;','&#201;'),('&Ecirc;', '&#202;'),('&Euml;',  '&#203;'),
                                              ('&Igrave;','&#204;'),('&Iacute;','&#205;'),('&Icirc;', '&#206;'),
                                              ('&Iuml;',  '&#207;'),('&ETH;',   '&#208;'),('&Ntilde;','&#209;'),
                                              ('&Ograve;','&#210;'),('&Oacute;','&#211;'),('&Ocirc;', '&#212;'),
                                              ('&Otilde;','&#213;'),('&Ouml;',  '&#214;'),('&times;', '&#215;'),
                                              ('&Oslash;','&#216;'),('&Ugrave;','&#217;'),('&Uacute;','&#218;'),
                                              ('&Ucirc;', '&#219;'),('&Uuml;',  '&#220;'),('&Yacute;','&#221;'),
                                              ('&THORN;', '&#222;'),('&szlig;', '&#223;'),('&agrave;','&#224;'),
                                              ('&aacute;','&#225;'),('&acirc;', '&#226;'),('&atilde;','&#227;'),
                                              ('&auml;',  '&#228;'),('&aring;', '&#229;'),('&aelig;', '&#230;'),
                                              ('&ccedil;','&#231;'),('&egrave;','&#232;'),('&eacute;','&#233;'),
                                              ('&ecirc;', '&#234;'),('&euml;',  '&#235;'),('&igrave;','&#236;'),
                                              ('&iacute;','&#237;'),('&icirc;', '&#238;'),('&iuml;',  '&#239;'),
                                              ('&eth;',   '&#240;'),('&ntilde;','&#241;'),('&ograve;','&#242;'),
                                              ('&oacute;','&#243;'),('&ocirc;', '&#244;'),('&otilde;','&#245;'),
                                              ('&ouml;',  '&#246;'),('&divide;','&#247;'),('&oslash;','&#248;'),
                                              ('&ugrave;','&#249;'),('&uacute;','&#250;'),('&ucirc;', '&#251;'),
                                              ('&uuml;',  '&#252;'),('&yacute;','&#253;'),('&thorn;', '&#254;'),
                                              ('&yuml;',  '&#255;'));

const CharSet:array [0..255] of char=(' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
                                      ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
                                      ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
                                      ' ',' ',' ','!','"','#','$','%','&','''',
                                      '(',')','*','+',',','-','.','/','0','1',
                                      '2','3','4','5','6','7','8','9',':',';',
                                      '<','=','>','?','@','A','B','C','D','E',
                                      'F','G','H','I','J','K','L','M','N','O',
                                      'P','Q','R','S','T','U','V','W','X','Y',
                                      'Z','[','\',']','^','_','`','a','b','c',
                                      'd','e','f','g','h','i','j','k','l','m',
                                      'n','o','p','q','r','s','t','u','v','w',
                                      'x','y','z','{','|','}','~','','€','',
                                      '‚','ƒ','„','…','†','‡','ˆ','‰','Š','‹',
                                      'Œ','','Ž','','','‘','’','“','”','•',
                                      '–','—','˜','™','š','›','œ','','ž','Ÿ',
                                      ' ','¡','¢','£','¤','¥','¦','§','¨','©',
                                      'ª','«','¬','­','®','¯','°','±','²','³',
                                      '´','µ','¶','·','¸','¹','º','»','¼','½',
                                      '¾','¿','À','Á','Â','Ã','Ä','Å','Æ','Ç',
                                      'È','É','Ê','Ë','Ì','Í','Î','Ï','Ð','Ñ',
                                      'Ò','Ó','Ô','Õ','Ö','×','Ø','Ù','Ú','Û',
                                      'Ü','Ý','Þ','ß','à','á','â','ã','ä','å',
                                      'æ','ç','è','é','ê','ë','ì','í','î','ï',
                                      'ð','ñ','ò','ó','ô','õ','ö','÷','ø','ù',
                                      'ú','û','ü','ý','þ','ÿ');

procedure THTMLText.SetLine(Line: string);
var
  j,i: integer;
  isEntity: boolean;
  Entity: string;
  EnLen, EnPos: integer;
  d, c: integer;
begin
  fRawLine:=Line;
  while pos(#10,Line)>0 do Line[Pos(#10,Line)]:=' ';
  while pos('  ',Line)>0 do delete(Line,pos('  ',Line),1);
  i:=1; isEntity:=false; EnPos:=0;
  while (i<=Length(Line)) do
    begin
      if Line[i]='&' then
        begin
          EnPos:=i;
          isEntity:=true;
          Entity:=''
        end;
      if isEntity then Entity:=Entity+Line[i];
      if isEntity then
        if (Line[i]=';') or (Line[i]=' ') then
          begin
            EnLen:=Length(Entity);
            if (EnLen>2) and (Entity[2]='#') then
              begin
                delete(Entity,EnLen,1);
                delete(Entity,1,2);
                if uppercase(Entity[1])='X' then Entity[1]:='$';
                if (Length(Entity)<=3) then
                  begin
                    val(Entity,d,c);
                    if c=0 then
                      begin
                        delete(Line,EnPos,EnLen);
                        insert(Charset[d],Line,EnPos);
                        i:=EnPos
                      end
                  end
              end
            else
              begin
                j:=1;
                while (j <= 100) do
                  begin
                    if Entity = (Entities[j,1]) then
                      begin
                        delete(Line,EnPos,EnLen);
                        insert(Entities[j,2],Line,Enpos);
                        j:=102
                      end;
                    j:=j+1
                  end;
                if j=103 then i:=EnPos-1
                else i:=EnPos;
              end;
            IsEntity:=false
          end;
      i:=i+1
    end;
  fLine:=Line
end;

procedure THTMLParam.SetKey(Key: string);
begin
  fValue:=''; fRaw:=Key;
  if pos('=',key)<>0 then
    begin
     fValue:=Key;
     delete(fValue,1,pos('=',key));
     key:=copy(Key,1,pos('=',key)-1);
     if length(fValue)>1 then
       if (fValue[1]='"') and (fValue[Length(fValue)]='"') then
         begin
           delete(fValue,1,1);
           delete(fValue,Length(fValue),1)
         end
    end;
  fKey:=uppercase(key)
end;

constructor THTMLParam.Create;
begin
  inherited Create
end;

destructor THTMLParam.Destroy;
begin
  inherited Destroy
end;

constructor THTMLText.Create;
begin
  inherited Create
end;

destructor THTMLText.Destroy;
begin
  inherited Destroy
end;

end.
