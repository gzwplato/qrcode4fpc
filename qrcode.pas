{****************************************************************************
*                                                                           *
*                          qrcode generator                                 *
*                                                                           *
*                                                                           *
* Language:             FPC Pascal v2.6.2+ / Delphi 6+                      *
*                                                                           *
* Required switches:    none                                                *
*                                                                           *
* Author:               Dariusz Mazur                                       *
* Date:                 20.09.2013                                          *
* Version:              1.0                                                 *
* Licence:              MPL or LGPL with exception
*                                                                           *
*        Send bug reports and feedback to  darekm @@ emadar @@ com          *
*   You can always get the latest version/revision of this package from     *
*                                                                           *
*              https://github.com/darekm/qrcode4fpc                         *
*                                                                           *
*                                                                           *
* Description: output a QRcode image in Pascal.
*              These library support QRcode model2 version1-40,
*               based on http://www.swetake.com/qrcode/                     *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*                                                                           *
*****************************************************************************
*                      BEGIN LICENSE BLOCK                                  *

The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: qrcode.pas, released 10.12.2012.
The Initial Developer of the Original Code is Dariusz Mazur


Alternatively, the contents of this file may be used under the terms of the
     GNU Library General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at your
option) any later version with the following modification:
As a special exception, the copyright holders of this library give you
permission to link this library with independent modules to produce an
executable, regardless of the license terms of these independent modules,and
to copy and distribute the resulting executable under terms of your choice,
provided that you also meet, for each linked independent module, the terms
and conditions of the license of that module. An independent module is a
module which is not derived from or based on this library. If you modify
this library, you may extend this exception to your version of the library,
but you are not obligated to do so. If you do not wish to do so, delete this
exception statement from your version.
This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
for more details.
You should have received a copy of the GNU Library General Public License
along with this library; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
GNU General Public License Version 2 (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

*                     END LICENSE BLOCK                                     * }
unit qrcode;

interface

uses
  SysUtils,
  Classes;

{$H+}

{
#   d= data         URL encoded data.
#   e= ECC level    L or M or Q or H   (default M)
#   s= module size  (dafault PNG:4 JPEG:8)
#   v= version      1-40 or Auto select if you do not set.
#   t= image type   J:jpeg image , other: PNG image
#
#  structured append  m of n (experimental)
#   n= structure append n (2-16)
#   m= structure append m (1-16)
#   p= parity
#   o= original data (URL encoded data)  for calculating parity
#
}

type
  tCodeWord = array[0..40] of integer;

  tQrImageType = (qrjpeg, qrpng);
  tInd = (ind_xor, ind_or);
  QrException = class(Exception);
  tSBytes = array of byte;
  tSIntegers = array of integer;

  tArrayIntegers = array of array of integer;

  tQrCode = class
  private
    version: integer;
    data_counter: integer;
    data_value, data_bits: array of integer;
    data_string: string;
    data_Length: integer;
    codeword_num_plus: tCodeWOrd;
    total_data_bits: integer;
    codeword_num_counter_value: integer;
    rs_ecc_codeWords: byte;
    rs_block_order: array[0..127] of byte;
    rscaltablearray: array of string;
    matrix_content: tArrayIntegers;
    matrix_y, matrix_x: tSBytes;
    maskArray: tSBytes;
    codewords: tSBytes;
    frameData: tsBytes;
    format_information_x2, format_information_y2: array[0..14] of byte;
    mask_content: integer;

    function rawurldecode(astr: string): string;
    procedure divideDataBy8bits(amax: integer);
    procedure setTerminator(aMax: integer);
    procedure readDatFile(aec, aWords: integer);
    procedure readCalTable(ars: integer);
    procedure readFrameData;
    procedure flashMatrix;
    procedure attachData(codeWordsRes: string);
    //     procedure arrayMerge;
    function selectMask(aRemainBit: integer): integer;
    procedure formatInformation(aec: integer);
    function calculateByteArrayBits(xa, xb: string; aInd: tInd): string;
    function PenaltyRule3(x, y, aSize, aMask: integer): integer;

  public
    encode_mode: (ALPHA_NUMERIC, NUMERIC, EBYTE);
    error_correction: char;
    xCalculationEcc: ansistring;

    module_size: integer;//@$_GET["s"];
    //    qrcode_version:integer;//=@$_GET["v"];
    image_type: tQrImageType;//=@$_GET["t"];

    qrcode_structureappend_n: integer;//=@$_GET["n"];
    qrcode_structureappend_m: integer;//=@$_GET["m"];
    qrcode_structureappend_parity: integer;//=@$_GET["p"];
    qrcode_structureappend_originaldata: string;//=@$_GET["o"];




    constructor Create;
    procedure setData(astr: string);
    function calculateRSecc(aMax: integer): string;
    procedure calQrCode(aData: string);
    function encode(acontent: string): ansistring;
    procedure outputImage;
    function getCodeWords: ansistring;
    function getMask: integer;
    procedure encodeMode;
    function encodeecc: integer;
    class  function alphaNumericCode(ch: char): integer;

  end;

implementation

 {$R qrcode.res}

const
  codeword_Bytes: tCOdeWord      = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8);
  max_codewords_array: tCodeWord = (0, 26, 44, 70, 100, 134, 172, 196, 242,
    292, 346, 404, 466, 532, 581, 655, 733, 815, 901, 991, 1085, 1156,
    1258, 1364, 1474, 1588, 1706, 1828, 1921, 2051, 2185, 2323, 2465,
    2611, 2761, 2876, 3034, 3196, 3362, 3532, 3706);
  codeword_alphaNumeric: tCodeWord = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4);

  codeword_numeric: tCodeWord = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4);

  matrix_remain_bit: tCodeWord =
    (0, 0, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0);

  format_information_x1: array[0..14] of integer =
    (0, 1, 2, 3, 4, 5, 7, 8, 8, 8, 8, 8, 8, 8, 8);
  format_information_y1: array[0..14] of integer =
    (8, 8, 8, 8, 8, 8, 8, 8, 7, 5, 4, 3, 2, 1, 0);


  format_information_array: array[0..31] of string =
    ('101010000010010', '101000100100101',
    '101111001111100', '101101101001011', '100010111111001', '100000011001110',
    '100111110010111', '100101010100000', '111011111000100', '111001011110011',
    '111110110101010', '111100010011101', '110011000101111', '110001100011000',
    '110110001000001', '110100101110110', '001011010001001', '001001110111110',
    '001110011100111', '001100111010000', '000011101100010', '000001001010101',
    '000110100001100', '000100000111011', '011010101011111', '011000001101000',
    '011111100110001', '011101000000110', '010010010110100', '010000110000011',
    '010111011011010', '010101111101101');



  version_ul = 40;

// ------ setting area ------ */

constructor tQrCode.Create;
begin
  encode_mode := ALPHA_NUMERIC;

  version := -1;              // upper limit for version
  // ------ setting area end ------ */

{
$qrcode_data_string=@$_GET["d"];
$qrcode_error_correct=@$_GET["e"];
$qrcode_module_size=@$_GET["s"];
$qrcode_version=@$_GET["v"];
$qrcode_image_type=@$_GET["t"];

$qrcode_structureappend_n=@$_GET["n"];
$qrcode_structureappend_m=@$_GET["m"];
$qrcode_structureappend_parity=@$_GET["p"];
$qrcode_structureappend_originaldata=@$_GET["o"];
}
(*
if (($qrcode_image_type=="J")||($qrcode_image_type=="j")){
    $qrcode_image_type="jpeg";
}else {
    $qrcode_image_type="png";
}


if ($qrcode_module_size>0) {
} else {
    if ($qrcode_image_type=="jpeg"){
        $qrcode_module_size=8;
    } else {
        $qrcode_module_size=4;
    }
}

*)

  module_size := 4;
end;


procedure tQrCode.setdata;
var
  originaldata_length: integer;
  i: integer;
begin

  data_string := rawurldecode(aStr);
  data_length := length(data_string);
  if encode_Mode = ALPHA_NUMERIC then
  begin
    for i := 1 to length(data_string) do
      if alphanumericCode(data_string[i])<0 then
      begin
        encode_Mode := EBYTE;
        break;
      end;
  end;
  Error_Correction := 'H';
  if (data_length<=0) then
  begin
    raise QrException.Create('Data do not exist');
  end;
  setlength(data_Value, data_Length + 32);
  setLength(data_Bits, data_Length + 32);

  data_counter := 0;
  if (qrcode_structureappend_n>1)  and (qrcode_structureappend_n<=16)  and
    (qrcode_structureappend_m>0)  and (qrcode_structureappend_m<=16) then
  begin

    data_value[0] := 3;
    data_bits[0] := 4;

    data_value[1] := qrcode_structureappend_m-1;
    data_bits[1] := 4;

    data_value[2] := qrcode_structureappend_n-1;
    data_bits[2] := 4;


    originaldata_length := lhttp://www.swetake.com/qr/qr8.htmlength(qrcode_structureappend_originaldata);
    if (originaldata_length>1) then
    begin
      qrcode_structureappend_parity := 0;
      for i := 1 to originaldata_length do
        qrcode_structureappend_parity :=
          (qrcode_structureappend_parity xor
          Ord(qrcode_structureappend_originaldata[i]));
    end;

    data_value[3] := qrcode_structureappend_parity;
    data_bits[3] := 8;

    data_counter := 4;
  end;
  data_bits[data_counter] := 4;
end;



class  function tQrCode.alphaNumericCode(ch: char): integer;
begin
{    alphanumeric_character_hash=array("0"=>0,"1"=>1,"2"=>2,"3"=>3,"4"=>4,
"5"=>5,"6"=>6,"7"=>7,"8"=>8,"9"=>9,"A"=>10,"B"=>11,"C"=>12,"D"=>13,"E"=>14,
"F"=>15,"G"=>16,"H"=>17,"I"=>18,"J"=>19,"K"=>20,"L"=>21,"M"=>22,"N"=>23,
"O"=>24,"P"=>25,"Q"=>26,"R"=>27,"S"=>28,"T"=>29,"U"=>30,"V"=>31,
"W"=>32,"X"=>33,"Y"=>34,"Z"=>35," "=>36,"$"=>37,"%"=>38,"*"=>39,
"+"=>40,"-"=>41,"."=>42,"/"=>43,":"=>44);}
  case ch of
    '0': Result := 0;
    '1': Result := 1;
    '2': Result := 2;
    '3': Result := 3;
    '4': Result := 4;
    '5': Result := 5;
    '6': Result := 6;
    '7': Result := 7;
    '8': Result := 8;
    '9': Result := 9;
    'A': Result := 10;
    'B': Result := 11;
    'C': Result := 12;
    'D': Result := 13;
    'E': Result := 14;
    'F': Result := 15;
    'G': Result := 16;
    'H': Result := 17;
    'I': Result := 18;
    'J': Result := 19;
    'K': Result := 20;
    'L': Result := 21;
    'M': Result := 22;
    'N': Result := 23;
    'O': Result := 24;
    'P': Result := 25;
    'Q': Result := 26;
    'R': Result := 27;
    'S': Result := 28;
    'T': Result := 29;
    'U': Result := 30;
    'V': Result := 31;
    'W': Result := 32;
    'X': Result := 33;
    'Y': Result := 34;
    'Z': Result := 35;
    ' ': Result := 36;
    '$': Result := 37;
    '%': Result := 38;
    '*': Result := 39;
    '+': Result := 40;
    '-': Result := 41;
    '.': Result := 42;
    '/': Result := 43;
    ':': Result := 44;
    else
      Result := -1;
  end;
end;

//*  --- determine encode mode */
procedure tQrCode.encodeMode;
var
  i: integer;

begin
  //if (preg_match("/[^0-9]/",$qrcode_data_string)!=0)then begin
  //    if (preg_match("/[^0-9A-Z \$\*\%\+\.\/\:\-]/",qrcode_data_string)!=0) then begin
  case Encode_Mode of

    //* ---- alphanumeric mode ---  */
    eByte:
    begin

      //  --- 8bit byte mode */

      codeword_num_plus := codeword_bytes;
      //        array(0,0,0,0,0,0,0,0,0,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8);

      data_value[data_counter] := 4;
      Inc(data_counter);
      data_value[data_counter] := data_length;
      data_bits[data_counter] := 8;   // #version 1-9 */
      codeword_num_counter_value := data_counter;

      Inc(data_counter);
      for i := 1 to data_length do
      begin
        data_value[data_counter] := Ord(data_string[i]);
        data_bits[data_counter] := 8;
        Inc(data_counter);
      end;
    end;
    Alpha_Numeric:
    begin
      codeWord_num_plus := codeWord_alphanumeric;
      //* ---- alphanumeric mode */

{        codeword_num_plus=array(0,0,0,0,0,0,0,0,0,0,
2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
4,4,4,4,4,4,4,4,4,4,4,4,4,4);
}
      data_value[data_counter] := 2;
      Inc(data_counter);
      data_value[data_counter] := data_length;
      data_bits[data_counter] := 9;  // #version 1-9 */
      codeword_num_counter_value := data_counter;



      Inc(data_counter);
      for i := 1 to data_length do
      begin
        if ((i mod 2) = 1) then
        begin
          data_value[data_counter] := alphanumericCode(data_string[i]);
          data_bits[data_counter] := 6;
        end
        else
        begin
          data_value[data_counter] :=
            data_value[data_counter]*45+alphanumericCode(data_string[i]);
          data_bits[data_counter] := 11;
          Inc(data_counter);
        end;
      end;

    end;
    numeric:
    begin

      codeword_num_plus := codeword_numeric;
      //* ---- numeric mode */
   {
    codeword_num_plus=array(0,0,0,0,0,0,0,0,0,0,
2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
4,4,4,4,4,4,4,4,4,4,4,4,4,4);
    }
      data_value[data_counter] := 1;
      Inc(data_counter);
      data_value[data_counter] := data_length;
      data_bits[data_counter] := 10;   //* #version 1-9 */
      codeword_num_counter_value := data_counter;

      Inc(data_counter);
      for i := 1 to data_length do
      begin
        case ((i-1) mod 3) of
          0:
          begin
            data_value[data_counter] := Ord(data_string[i]);
            data_bits[data_counter] := 4;
          end;
          1:
          begin
            data_value[data_counter] := data_value[data_counter]*10+Ord(data_string[i]);
            data_bits[data_counter] := 7;
          end;
          2:
          begin
            data_value[data_counter] := data_value[data_counter]*10+Ord(data_string[i]);
            //         if ((i mod 3)=1)then begin
            //             data_bits[data_counter]:=7;
            //         end else begin
            data_bits[data_counter] := 10;
            Inc(data_counter);
          end;
        end;
      end;
    end;
  end;
  if (data_bits[data_counter]>0) then
  begin
    Inc(data_counter);
  end;
  total_data_bits := 0;
  for i := 0 to data_counter do
  begin
    Inc(total_data_bits, data_bits[i]);
  end;

end;

const
  max_data_bits_array: array[0..160] of integer = (
    0, 128, 224, 352, 512, 688, 864, 992, 1232, 1456, 1728,
    2032, 2320, 2672, 2920, 3320, 3624, 4056, 4504, 5016, 5352,
    5712, 6256, 6880, 7312, 8000, 8496, 9024, 9544, 10136, 10984,
    11640, 12328, 13048, 13800, 14496, 15312, 15936, 16816, 17728, 18672,

    152, 272, 440, 640, 864, 1088, 1248, 1552, 1856, 2192,
    2592, 2960, 3424, 3688, 4184, 4712, 5176, 5768, 6360, 6888,
    7456, 8048, 8752, 9392, 10208, 10960, 11744, 12248, 13048, 13880,
    14744, 15640, 16568, 17528, 18448, 19472, 20528, 21616, 22496, 23648,

    72, 128, 208, 288, 368, 480, 528, 688, 800, 976,
    1120, 1264, 1440, 1576, 1784, 2024, 2264, 2504, 2728, 3080,
    3248, 3536, 3712, 4112, 4304, 4768, 5024, 5288, 5608, 5960,
    6344, 6760, 7208, 7688, 7888, 8432, 8768, 9136, 9776, 10208,

    104, 176, 272, 384, 496, 608, 704, 880, 1056, 1232,
    1440, 1648, 1952, 2088, 2360, 2600, 2936, 3176, 3560, 3880,
    4096, 4544, 4912, 5312, 5744, 6032, 6464, 6968, 7288, 7880,
    8264, 8920, 9368, 9848, 10288, 10832, 11408, 12016, 12656, 13328);

function tQrCode.encodeEcc;

  function eccHash(ch: char): integer;
  begin
 {
$ecc_character_hash=array("L"=>"1",
"l"=>"1",
"M"=>"0",
"m"=>"0",
"Q"=>"3",
"q"=>"3",
"H"=>"2",
"h"=>"2");
}
    case ch of
      'L', 'l': Result := 1;
      'M', 'm': Result := 0;
      'Q', 'q': Result := 3;
      'H', 'h': Result := 2;
      else
        Result := 0;
    end;
  end;

var
  ec:   integer;
  i, j: integer;
  max_data_bits: integer;
  max_codewords: integer;
begin

  ec := ecchash(error_correction);
  Result := ec;

  // if (!$ec){$ec=0;}
(*
$max_data_bits_array=array(
0,128,224,352,512,688,864,992,1232,1456,1728,
2032,2320,2672,2920,3320,3624,4056,4504,5016,5352,
5712,6256,6880,7312,8000,8496,9024,9544,10136,10984,
11640,12328,13048,13800,14496,15312,15936,16816,17728,18672,

152,272,440,640,864,1088,1248,1552,1856,2192,
2592,2960,3424,3688,4184,4712,5176,5768,6360,6888,
7456,8048,8752,9392,10208,10960,11744,12248,13048,13880,
14744,15640,16568,17528,18448,19472,20528,21616,22496,23648,

72,128,208,288,368,480,528,688,800,976,
1120,1264,1440,1576,1784,2024,2264,2504,2728,3080,
3248,3536,3712,4112,4304,4768,5024,5288,5608,5960,
6344,6760,7208,7688,7888,8432,8768,9136,9776,10208,

104,176,272,384,496,608,704,880,1056,1232,
1440,1648,1952,2088,2360,2600,2936,3176,3560,3880,
4096,4544,4912,5312,5744,6032,6464,6968,7288,7880,
8264,8920,9368,9848,10288,10832,11408,12016,12656,13328
);
*)
  {
  if (is_numeric($qrcode_version)) then begin
    qrcode_version=0;
  end;
  }
  max_data_bits := -1;
  if (version<0) then
  begin
    //* #--- auto version select */
    i := 1+40*ec;
    j := i+39;
    version := 1;
    while (i<=j) do
    begin
      if ((max_data_bits_array[i])>=
        (total_data_bits+codeword_num_plus[version])) then
      begin
        max_data_bits := max_data_bits_array[i];
        break;
      end;
      Inc(i);
      Inc(version);
    end;

  end
  else
  begin
    max_data_bits := max_data_bits_array[version+40*ec];
  end;
  if (version>version_ul) then
  begin
    raise QRexception.Create('QRcode : too large version.');
    //  trigger_error("QRcode : too large version.",E_USER_ERROR);
  end;

  Inc(total_data_bits, codeword_num_plus[version]);
  Inc(data_bits[codeword_num_counter_value], codeword_num_plus[version]);
{
max_codewords_array: tCodeWords=(0,26,44,70,100,134,172,196,242,
                          292,346,404,466,532,581,655,733,815,901,991,1085,1156,
1258,1364,1474,1588,1706,1828,1921,2051,2185,2323,2465,
2611,2761,2876,3034,3196,3362,3532,3706);
}
  max_codewords := max_codewords_array[version];
{
$matrix_remain_bit=array(0,0,7,7,7,7,7,0,0,0,0,0,0,0,3,3,3,3,3,3,3,
4,4,4,4,4,4,4,3,3,3,3,3,3,3,0,0,0,0,0,0);
}
  //* ---- read version ECC data file */


  readDatFile(ec, max_codewords);
  readFrameData;
(*

*)
  setTerminator(max_data_bits);
  divideDataBy8Bits(max_data_bits);
  attachData(calculateRSECC(max_data_bits));
end;

//*  --- set terminator */


procedure tQrCode.setTerminator;
begin
  if (total_data_bits<=amax-4) then
  begin
    data_value[data_counter] := 0;
    data_bits[data_counter] := 4;
  end
  else
  begin
    if (total_data_bits<amax) then
    begin
      data_value[data_counter] := 0;
      data_bits[data_counter] := amax-total_data_bits;
    end
    else
    begin
      if (total_data_bits>amax) then
      begin
        raise qrException.Create('QRcode : Overflow error');
      end;
    end;
  end;
end;


procedure tQrCode.readDatFile;
var
  bytenum: integer;
  filename: string;
  ts: tStream;
begin

  bytenum := matrix_remain_bit[version]+(awords *8);
  filename := 'qrv'+IntToStr(version)+'z'+IntToStr(aec)+'_dat';
  ts := GenerateResourceStream(fileName);

  // $fp1 = fopen ($filename, "rb");
  //  ts.read(matx,bytenum);
  //    $matx=fread($fp1,$byte_num);
  setLength(matrix_x, bytenum);
  ts.Read(pointer(matrix_x)^, bytenum);//=fread($fp1,$byte_num);
  setLength(matrix_y, bytenum);
  ts.Read(pointer(matrix_y)^, bytenum);//=fread($fp1,$byte_num);
  setLength(maskarray, bytenum);
  ts.Read(pointer(maskarray)^, bytenum);// $masks=fread($fp1,$byte_num);
  ts.Read(format_information_x2, 15);// $fi_x=fread($fp1,15);
  ts.Read(format_information_y2, 15);// $fi_y=fread($fp1,15);
  ts.Read(rs_ecc_codewords, 1);// $rs_ecc_codewords=ord(fread($fp1,1));
  ts.Read(rs_block_order, 128);// $rso=fread($fp1,128);
  ts.Free;
  // fclose($fp1);

  // $rs_block_order=unpack("C*",$rso);


end;

procedure tQrCode.readCalTable;
var
  i:  integer;
  fileName: string;
  ts: tStream;
begin

  filename := 'rsc'+IntToStr(ars)+'_dat';
  ts := GenerateResourceStream(fileName);
  setLength(rscaltablearray, 256);

  for i := 0 to 255 do
  begin
    setLength(rscaltablearray[i], ars);
    ts.Read(pointer(rscaltablearray[i])^, ars);
    //    $rs_cal_table_array[$i]=fread ($fp0,$rs_ecc_codewords);
  end;
  ts.Free;

end;

procedure tqrCode.readFrameData;
var
  //  i : integer;
  fileName: string;
  ts:     tStream;
  x, m1s: integer;
begin
  filename := 'qrvfr'+IntToStr(version)+'_dat';
  ts := GenerateResourceStream(fileName);
  m1s := 4*version+17;
  x := m1s*m1s+m1s;
  setLength(frameData, x);
  ts.Read(pointer(framedata)^, x);
  ts.Free;
end;


//* ----divide data by 8bit */

procedure tQrCode.divideDataBy8Bits;
var
  i:    integer;
  flag: boolean;
  codewords_counter, remaining_bits, buffer, buffer_bits: integer;
  max_data_codewords: integer;
begin

  i := 0;
  codewords_counter := 0;
  remaining_bits := 8;
  max_data_codewords := (amax shr 3);

  setLength(codewords, max_Data_Codewords);
  codewords[0] := 0;

  while (i<=data_counter) do
  begin
    buffer := data_value[i];
    buffer_bits := data_bits[i];

    flag := True;
    if buffer_bits = 0 then
      break;
    while (flag) do
    begin
      if (remaining_bits>buffer_bits) then
      begin
        codewords[codewords_counter] :=
          ((codewords[codewords_counter]shl buffer_bits) or buffer);
        Dec(remaining_bits, buffer_bits);
        flag := False;
      end
      else
      begin
        Dec(buffer_bits, remaining_bits);
        codewords[codewords_counter] :=
          ((codewords[codewords_counter] shl remaining_bits) or
          (buffer shr buffer_bits));

        if (buffer_bits = 0) then
        begin
          flag := False;

        end
        else
        begin
          buffer := (buffer and ((1 shl buffer_bits)-1));
          flag := True;
        end;

        Inc(codewords_counter);
        if (codewords_counter<(max_data_codewords-1)) then
        begin
          codewords[codewords_counter] := 0;
        end;
        remaining_bits := 8;
      end;
    end;
    Inc(i);
  end;
  if (remaining_bits<>8) then
  begin
    codewords[codewords_counter] := codewords[codewords_counter] shl remaining_bits;
  end
  else
  begin
    Dec(codewords_counter);
  end;

  if (codewords_counter<max_data_codewords-1) then
  begin
    flag := True;
    while (codewords_counter<max_data_codewords-1) do
    begin
      Inc(codewords_counter);
      if (flag) then
      begin
        codewords[codewords_counter] := 236;
      end
      else
      begin
        codewords[codewords_counter] := 17;
      end;
      flag := not flag;
    end;
  end;
end;

function tQrCode.getCodeWords;
var
  i: integer;
begin
  Result := '';
  for i := 1 to length(codewords) do

    Result := Result+chr(codewords[i-1]);
end;

//* ---- RS-ECC prepare */
function tQrCode.calculateRSecc;
var
  i2, i, j: integer;
  rsblocknumber: integer;
  rs_block_order_length: integer;
  rs_data_codewords: integer;
  rs_codeWords: integer;
  rsTemp:  array of string;
  rsTempData: string;
  First:   char;
  cal:     string;
  leftchr: string;
  //  max_codeWords : integer;
  max_data_codewords: integer;
begin
  //  max_codewords:=max_codewords_array[version];

  readCalTable(rs_ecc_codeWords);
  rs_block_order_length := length(rs_block_order);

  i := 0;
  j := 0;
  rsblocknumber := 0;
  setLength(rsTemp, rs_block_order_length);
  rstemp[0] := '';
  max_data_codewords := (amax shr 3);
  for i2 := 0 to rs_block_order_length-1 do
  begin
    setlength(rsTemp[i2], rs_block_order[i2]-rs_ecc_codewords);
  end;

  i := 0;
  j := 0;
  Result := '';
  while (i<max_data_codewords) do
  begin
    Inc(j);
    rstemp[rsblocknumber][j] := chr(codewords[i]);
    Result := Result+chr(codewords[i]);
    //    inc(j);
    if (j>=rs_block_order[rsblocknumber]-rs_ecc_codewords) then
    begin
      j := 0;
      Inc(rsblocknumber);
      //        rstemp[rsblocknumber]:='';
    end;
    Inc(i);
  end;

{*
#
# RS-ECC main
#
*}

  rsblocknumber := 0;
  //  result:='';

  while (rsblocknumber<rs_block_order_length) do
  begin
    //    setLength(rsTempData,length(rsTemp[rsBlockNumber]));
    rs_codewords := rs_block_order[rsblocknumber];
    rs_data_codewords := rs_codewords-rs_ecc_codewords;

    rstempData := rstemp[rsblocknumber];
    //     + str_repeat(chr(0),rs_ecc_codewords);
    //    padding_data:=str_repeat(chr(0),rs_data_codewords);

    j := rs_data_codewords;
    while (j>0) do
    begin
      First := rstempData[1];

      if First<>#0 then
      begin
        leftchr := copy(rstempData, 2, length(rsTempData));
        cal := rscaltablearray[Ord(First)];
        rstempData := calculateByteArrayBits(leftchr, cal, ind_xor);
      end
      else
      begin
        if rs_Ecc_Codewords<=length(rsTempData) then
        begin
          rsTempData := copy(rsTempdata, 2, length(rsTempData)-1);
        end
        else
        begin
          rsTempData := copy(rsTempdata, 2, length(rsTempData)-1)+#0;
        end;
        //            delete(rsTempData,1,1);

        //            rstemp=tr($rstemp,1);
      end;

      Dec(j);
    end;
    Result := Result+rsTempData;
    //    arrayMerge;
    //    codewords:=array_merge($codewords,unpack("C*",$rstemp));

    Inc(rsblocknumber);
  end;
  xCalculationECC := Result;
end;


//* ---- flash matrix */
procedure tQrCode.flashMatrix;
var
  i, j: integer;
  modules_1Size: integer;
begin
  modules_1Size := 4 * Version + 17;
  setLength(matrix_content, modules_1size);
  for i := 0 to modules_1size-1 do
  begin
    setLength(matrix_content[i], modules_1size);
    for j := 0 to modules_1size -1 do
    begin
      matrix_content[i, j] := 0;

    end;
  end;
end;

//* --- attach data */

procedure tQrCode.attachData;
var
  i, j: integer;
  codeword_i: byte;
  bits_number: integer;
  remain_bit_temp, matrix_remain: integer;

  //  ver_master : string;
  max_codewords: integer;
begin
  flashMatrix;
  max_codewords := max_codewords_array[version];

  for i := 0 to max_codewords-1 do
  begin
    codeword_i := Ord(codewordsres[i+1]);
    for j := 7 downto 0 do
    begin
      bits_number := (i *8) +  j;
      matrix_content[matrix_x[bits_number]][matrix_y[bits_number]] :=
        ((255*(codeword_i and  1)) xor maskarray[bits_number]);
      codeword_i := codeword_i shr 1;
    end;
  end;

  matrix_remain := matrix_remain_bit[version];
  while (matrix_remain<>0) do
  begin
    remain_bit_temp := matrix_remain + (max_codewords shl 3);
    Dec(remain_bit_temp);
    matrix_content[matrix_x[remain_bit_temp]][matrix_y[remain_bit_temp]] :=
      (255 xor maskarray[remain_bit_temp]);
    Dec(matrix_remain);
  end;

end;
//#--- mask select


function tQrCode.PenaltyRule3(x, y, aSize, aMask: integer): integer;

  function f(ax, ay: integer): boolean;
  begin
    Result := ((matrix_Content[ax][ay] shr amask) and 1)<>0;
  end;

begin
  Result := 0;
  if (x + 6 < aSize) and  f(y, x) and  not  f(y, x+1)and  f(y, x+2) and
    f(y, x+3) and  f(y, x+4) and  not f(y, x+5) and  f(y, x+6) and
    (((x + 10 < aSize) and  not  f(y, x +  7) and  not f(y, x +  8) and
    not  f(y, x +  9) and  not f(y, x + 10)) or  ((x - 4 >= 0) and
    not f(y, x -  1) and  not f(y, x -  2)  and  not  f(y, x -  3) and
    not f(y, x -  4))) then
    Inc(Result, 40);

  if (y + 6 < aSize) and  f(y, x)  and  not  f(y+1, x) and  f(y+2, x) and
    f(y+3, x) and  f(y+4, x) and  not f(y+5, x) and  f(y+6, x) and
    (((y + 10 < asize) and not f(y +  7, x) and  not f(y +  8, x) and not
    f(y +  9, x) and not f(y + 10, x)) or  ((y - 4 >= 0)  and not
    f(y -  1, x) and not f(y -  2, x) and  not f(y -  3, x) and not f(y -  4, x))) then
    Inc(Result, 40);
end;


function tQrCode.SelectMask;
var
  y, x, ll:    integer;
  d4Counter, xData, yData, d5, d1, d2, d3, d4: array[0..7] of integer;
  xD1Flag, yD1Flag: array[0..7] of boolean;
  d2And, d2Or: integer;
  MinValue:    integer;
  demerit:     integer;
  maskNumber:  integer;
const
  d4Value: array[0..20] of integer = (90, 80, 70, 60, 50, 40, 30, 20,
    10, 0, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 90);

begin
  ll := length(matrix_Content)-1;
  d2And := 0;
  d2Or := 0;
  fillchar(d1, sizeof(d1), 0);
  fillchar(d2, sizeof(d2), 0);
  fillchar(d3, sizeof(d3), 0);
  fillchar(d4, sizeof(d4), 0);
  fillchar(d5, sizeof(d5), 0);
  fillchar(d4Counter, sizeof(d4Counter), 0);

  for y := 0 to ll do
  begin
    fillchar(xData, sizeof(xData), 0);
    fillchar(yData, sizeof(yData), 0);
    fillchar(xD1Flag, sizeof(xD1Flag), 0);
    fillchar(yD1Flag, sizeof(yD1Flag), 0);
    for x := 0 to ll do
    begin
      if (x > 0) and (y > 0) then
      begin
        d2And := matrix_Content[x][y] and matrix_Content[x - 1][y] and
          matrix_Content[x][y - 1] and matrix_Content[x - 1][y - 1] and $FF;
        d2Or := (matrix_Content[x][y]) or (matrix_Content[x - 1][y]) or
          (matrix_Content[x][y - 1]) or (matrix_Content[x - 1][y - 1]);
      end;
      for maskNumber := 0 to 7 do
      begin
        xData[maskNumber] :=
          ((xData[maskNumber] and 63) shl 1) or
          ((matrix_Content[x][y] shr maskNumber) and 1);
        yData[maskNumber] :=
          ((yData[maskNumber] and 63) shl 1) or
          ((matrix_Content[y][x] shr maskNumber) and 1);
        if ((matrix_Content[x][y] and (1 shl maskNumber)) <> 0) then
          Inc(d4Counter[maskNumber]);

        if (xData[maskNumber] = 93) then
          Inc(d3[maskNumber], 40);

        if (yData[maskNumber] = 93) then
          Inc(d3[maskNumber], 40);
        Inc(d5[maskNumber], PenaltyRule3(x, y, ll+1, maskNumber));

        if (x > 0) and (y > 0) then
        begin
          if (((d2And and 1) <> 0) or ((d2Or and 1) = 0)) then
          begin
            Inc(d2[maskNumber], 3);
          end;
          d2And := d2And shr 1;
          d2Or := d2Or shr 1;
        end;
        if (((xData[maskNumber] and $1F) = 0) or
          ((xData[maskNumber] and $1F) = $1F)) then
        begin
          if (x > 4) then
          begin
            if (xD1Flag[maskNumber]) then
            begin
              Inc(d1[maskNumber]);
            end
            else
            begin
              Inc(d1[maskNumber], 3);
              xD1Flag[maskNumber] := True;
            end;
          end;
        end
        else
        begin
          xD1Flag[maskNumber] := False;
        end;
        if (((yData[maskNumber] and $1F) = 0) or
          ((yData[maskNumber] and $1F) = $1F)) then
        begin
          if (x > 4) then
          begin
            if (yD1Flag[maskNumber]) then
            begin
              Inc(d1[maskNumber]);
            end
            else
            begin
              Inc(d1[maskNumber], 3);
              yD1Flag[maskNumber] := True;
            end;
          end;
        end
        else
        begin
          yD1Flag[maskNumber] := False;
        end;
      end;

    end;
  end;
  MinValue := 0;
  Result := 0;
  for maskNumber := 0 to 7 do
  begin
    d4[maskNumber] := d4Value[((20 * d4Counter[maskNumber]) div aRemainBit)];
    demerit := d1[maskNumber] + d2[maskNumber] + d5[maskNumber] + d4[maskNumber];
    d5[maskNumber] := demerit;
    if (demerit < MinValue) or (maskNumber = 0) then
    begin

      Result := maskNumber;
      MinValue := demerit;
    end;
  end;

end;

function tQrCode.getMask: integer;
begin
  Result := selectMask(matrix_remain_bit[version]+(max_codewords_array[version] *8));
end;



procedure tQrCode.formatInformation;
var
  i: integer;
  mask_number: integer;
  format_information_value: integer;
  content: integer;
begin
  mask_number := selectMask(matrix_remain_bit[version]+
    (max_codewords_array[version] *8));
  //  mask_number:=0;
  //# --- format information
  mask_content := 1 shl mask_number;

  format_information_value := ((aec shl 3) or mask_number);
  {
  format_information_array=array("101010000010010","101000100100101",
"101111001111100","101101101001011","100010111111001","100000011001110",
"100111110010111","100101010100000","111011111000100","111001011110011",
"111110110101010","111100010011101","110011000101111","110001100011000",
"110110001000001","110100101110110","001011010001001","001001110111110",
"001110011100111","001100111010000","000011101100010","000001001010101",
"000110100001100","000100000111011","011010101011111","011000001101000",
"011111100110001","011101000000110","010010010110100","010000110000011",
"010111011011010","010101111101101");
  }

  for i := 0 to 14 do
  begin
    if format_information_array[format_information_value][i+1] = '1' then
      content := 255
    else
      content := 0;

    matrix_content[format_information_x1[i]][format_information_y1[i]] := content;
    matrix_content[format_information_x2[i]][format_information_y2[i]] := content;
    //    $i++;
  end;
end;




procedure tQrCode.calQrCode;
begin
  setData(aData);
  encodeMode;

  //  attachData;
  formatInformation(encodeECC);
end;


function tQrCode.calculateByteArrayBits(xa, xb: string; aInd: tInd): string;
var
  i, lls: integer;

  xl, xs: string;
begin

  if length(xa) > length(xb) then
  begin
    xl := xa;
    xs := xb;
  end
  else
  begin
    xl := xb;
    xs := xa;
  end;

  lls := length(xs);
  Result := xl;

  for  i := 1 to length(xs) do
  begin
    if aInd = ind_xor then
    begin
      Result[i] := char(byte(xl[i]) xor byte(xs[i]));
    end
    else
    begin
      Result[i] := char(byte(xl[i]) or byte(xs[i]));
    end;

  end;
end;

function tQrCode.encode(acontent: string): ansistring;
var
  xx, c, i, j: integer;

begin
  //            bool[][] matrix =
  calQrcode(acontent);
  //            SolidBrush brush = new SolidBrush(qrCodeBackgroundColor);
  //            Bitmap image = new Bitmap( (matrix.Length * qrCodeScale) + 1, (matrix.Length * qrCodeScale) + 1);
  //            Graphics g = Graphics.FromImage(image);
  //            g.FillRectangle(brush, new Rectangle(0, 0, image.Width, image.Height));
  //            brush.Color = qrCodeForegroundColor ;
  Result := '';
  c := 0;
  xx := length(matrix_content)-1;
  for i := 0 to xx do
  begin
    for  j := 0 to xx do
    begin
      if ((matrix_content[j, i] and mask_Content)<>0) or  (frameData[c] = 49) then
      begin
        Result := Result+' 1';
      end
      else
      begin
        Result := Result+' 0';
      end;
      Inc(c);
    end;
    Inc(c);
    Result := Result+#10;
  end;
end;

procedure tQrCode.outputImage;
var
  mib, mxe: integer;
  max_Modules_1side: integer;
begin
  max_modules_1side := 17+(version *4);

  mib := max_modules_1side+8;
end;


function tQrCode.rawUrldecode;
begin
  Result := aStr;
end;

end.
