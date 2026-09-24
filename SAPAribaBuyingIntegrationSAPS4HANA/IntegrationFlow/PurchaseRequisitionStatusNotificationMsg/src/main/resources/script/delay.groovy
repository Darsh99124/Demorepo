import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;

def Message processData(Message message) {

  def map = message.getProperties();
  def MessageDelay = map.get("MessageDelay");
  Long MessageDelayLong = Long.valueOf(MessageDelay);

  sleep(MessageDelayLong);
  return message;
}
