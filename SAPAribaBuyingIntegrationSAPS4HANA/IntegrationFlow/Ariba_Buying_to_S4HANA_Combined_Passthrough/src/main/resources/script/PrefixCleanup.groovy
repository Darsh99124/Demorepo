import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;

def Message processData(Message message)
{
  def map = message.getProperties();

  def Prefix01 = map.get("Prefix01");
  def Prefix02 = map.get("Prefix02");
  def Prefix03 = map.get("Prefix03");
  def Prefix04 = map.get("Prefix04");
  def Prefix05 = map.get("Prefix05");
  def Prefix06 = map.get("Prefix06");
  def Prefix07 = map.get("Prefix07");
  def Prefix08 = map.get("Prefix08");
  def Prefix09 = map.get("Prefix09");
  def Prefix10 = map.get("Prefix10");
  def Prefix11 = map.get("Prefix11");
  def Prefix12 = map.get("Prefix12");
  def Prefix13 = map.get("Prefix13");
  def Prefix14 = map.get("Prefix14");
  def Prefix15 = map.get("Prefix15");
  def Prefix16 = map.get("Prefix16");
  def Prefix17 = map.get("Prefix17");
  def Prefix18 = map.get("Prefix18");
  def Prefix19 = map.get("Prefix19");
  def Prefix20 = map.get("Prefix20");

  def msgBodyOrig = message.getBody(java.lang.String) as String;

  def msgBodyMod01 = msgBodyOrig.replaceAll(/$Prefix01/,'');
  def msgBodyMod02 = msgBodyMod01.replaceAll(/$Prefix02/,'');
  def msgBodyMod03 = msgBodyMod02.replaceAll(/$Prefix03/,'');
  def msgBodyMod04 = msgBodyMod03.replaceAll(/$Prefix04/,'');
  def msgBodyMod05 = msgBodyMod04.replaceAll(/$Prefix05/,'');
  def msgBodyMod06 = msgBodyMod05.replaceAll(/$Prefix06/,'');
  def msgBodyMod07 = msgBodyMod06.replaceAll(/$Prefix07/,'');
  def msgBodyMod08 = msgBodyMod07.replaceAll(/$Prefix08/,'');
  def msgBodyMod09 = msgBodyMod08.replaceAll(/$Prefix09/,'');
  def msgBodyMod10 = msgBodyMod09.replaceAll(/$Prefix10/,'');
  def msgBodyMod11 = msgBodyMod10.replaceAll(/$Prefix11/,'');
  def msgBodyMod12 = msgBodyMod11.replaceAll(/$Prefix12/,'');
  def msgBodyMod13 = msgBodyMod12.replaceAll(/$Prefix13/,'');
  def msgBodyMod14 = msgBodyMod13.replaceAll(/$Prefix14/,'');
  def msgBodyMod15 = msgBodyMod14.replaceAll(/$Prefix15/,'');
  def msgBodyMod16 = msgBodyMod15.replaceAll(/$Prefix16/,'');
  def msgBodyMod17 = msgBodyMod16.replaceAll(/$Prefix17/,'');
  def msgBodyMod18 = msgBodyMod17.replaceAll(/$Prefix18/,'');
  def msgBodyMod19 = msgBodyMod18.replaceAll(/$Prefix19/,'');
  def msgBodyMod20 = msgBodyMod19.replaceAll(/$Prefix20/,'');

  message.setBody(msgBodyMod20);
  return message;
}
