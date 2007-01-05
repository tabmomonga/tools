#! /bin/env python

class spec_contents:
    def __init__(self, specfile):
        self.specfile = specfile
        self.macro_key = ['%global', '%define']
        self.macro = {}
        self.Sources = []
        self.nosrc = False
        self.srpm_name = ''
        self.Patches = []
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

        self.macro['name'] = self.Tag['Name']
        self.macro['version'] = self.Tag['Version']

        for line in content_lines:
            if line.startswith('Source'):
                self.Sources.append(line.split(' ')[-1].strip())
            elif line.startswith('%NoSource'):
                self.Sources.append(line.split(' ')[-2].strip())
                self.nosrc = True
            elif line.startswith('NoSource'):
                self.nosrc = True
        for i in range(len(self.Sources)):
            for key in self.macro.iterkeys():
                self.Sources[i] = \
                    self.Sources[i].replace('%{' + key + '}',self.macro[key])
                if self.Sources[i].find('/'):
                    self.Sources[i] = self.Sources[i].split('/')[-1]

        for line in content_lines:
            if line.startswith('Patch'):
                self.Patches.append(line.split(' ')[-1].strip())
        for i in range(len(self.Patches)):
            for key in self.macro.iterkeys():
                self.Patches[i] = \
                    self.Patches[i].replace('%{' + key + '}',self.macro[key])
                if self.Patches[i].find('/'):
                    self.Patches[i] = self.Patches[i].split('/')[-1]
        
        self.srpm_name = self.Tag['Name'] + '-' +\
                self.Tag['Version'] + '-' +\
                self.Tag['Release']
        if self.nosrc:
            self.srpm_name += '.nosrc.rpm'
        else:
            self.srpm_name += '.src.rpm'

if __name__ == "__main__":
    import sys
    content = spec_contents(sys.argv[1])
    content.parse_spec()
    print content.srpm_name
    print "SOURCE = ", content.Sources
    print "PATCH  = ", content.Patches
