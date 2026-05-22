///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS com.typesafe:config:1.4.8

import com.typesafe.config.ConfigRenderOptions;
import com.typesafe.config.ConfigFactory;
import com.typesafe.config.ConfigRenderOptions;
import java.io.File;

class resolve {
  public static void main(String[] args) throws Exception {
    var opts = ConfigRenderOptions.defaults()
        .setJson(true)
        .setComments(false)
        .setOriginComments(false);

    var profile = new File("CDtoTransport.profile");
    var config = ConfigFactory.parseFile(profile.getAbsoluteFile()).resolve();
    System.out.println(config.root().render(opts));
  }
}
