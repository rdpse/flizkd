#!/usr/bin/env python                                                                                                                                                                       $

from deluge.config import Config
import hashlib
import os.path
import sys

if len(sys.argv) == 2:
    deluge_dir = os.path.expanduser(sys.argv[1])

    if os.path.isdir(deluge_dir):
        try:
            config = Config("web.conf", config_dir=deluge_dir)
        except IOError, e:
            print "Can't open web ui config file: ", e
        else:
            from itertools import islice
            with open ("/root/pass.txt", "r") as myfile:
                password=myfile.read().replace('\n', '')
            s = hashlib.sha1()
            s.update(config['pwd_salt'])
            s.update(password)
            config['pwd_sha1'] = s.hexdigest()
            try:
                config.save()
            except IOError, e:
                print "Couldn't save new password: ", e
            else:
                print "New password successfully set!"
    else:
        print "%s is not a directory!" % deluge_dir
else:
    print "Usage: %s <deluge config dir>" % (os.path.basename(sys.argv[0]))

