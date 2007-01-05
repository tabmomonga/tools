#! /bin/env python

class spec_contents:
    def __init__(self, specfile):
        self.specfile = specfile
        self.macro_key = ['%global', '%define']
        self.macro = {}
        self.Tag = {'Name':'',
                    'Version':'',
                    'Release':''}
    def parse_spec(self):
        spec = open (self.specfile, 'r')
        content = spec.read()
        spec.close()
        content_lines = content.splitlines()
        for line in content_lines:
            for key in self.macro_key:
                if line.startswith(key):
                    self.macro[line.split()[1].strip()] = \
                        line.split()[2].strip()
        for line in content_lines:
            for key in self.Tag.iterkeys():
                if line.startswith(key):
                    self.Tag[key] = line.split(':')[1].strip()
        for item in self.Tag.iterkeys():
            for key in self.macro.iterkeys():
                self.Tag[item] = \
                    self.Tag[item].replace('%{' + key + '}',self.macro[key])

if __name__ == "__main__":
    import sys
    content = spec_contents(sys.argv[1])
    content.parse_spec()
    print content.Tag
