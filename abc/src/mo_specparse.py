#! /bin/env python

class spec_contents:
    def __init__(self, specfile):
        self.specfile = specfile
        self.Tag = {'Name':'',
                    'Version':'',
                    'Release':''}
    def parse_spec(self):
        spec = open (self.specfile, 'r')
        content = spec.read()
        spec.close()
        content_lines = content.splitlines()
        for line in content_lines:
            for key in self.Tag.iterkeys():
                if line.startswith(key):
                    self.Tag[key] = line.split(':')[1].lstrip().rstrip()

if __name__ == "__main__":
    content = spec_contents("/opt/trunk/pkgs/autoconf/autoconf.spec")
    content.parse_spec()
    print content.Tag
