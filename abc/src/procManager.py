#! /bin/env python

import os
import sys

class procManager:
    def __init__(self, buildList, max_proc):
        self.max_proc = max_proc
        self.buildList = buildList
        self.restList = buildList[:]
        self.successList = []
        self.failureList = []
        self.pendingList = []
    def procExec(self, command):
        pidList = []
        for pkg in self.buildList:
            pid = os.fork()
            if pid == 0:
                # we must create command line
                commandLine = command
                # run command line
                print commandLine
                status = os.system(commandLine)
                if status == 0:
                    self.successList.append(pkg)
                elif status != 0:
                    self.failureList.append(pkg)
                # we must check pending
                sys.exit(status)
            else:
                pidList.append([pkg, pid])
                self.restList.remove(pkg)
                print pidList
                # wait if over max processes
                while len(pidList) >= self.max_proc:
                    pid_end = os.wait()
                    for pkg_pid in pidList:
                        if pkg_pid[1] == pid_end[0]:
                            pidList.remove(pkg_pid)
        # wait all child process
        for pid in pidList:
            os.wait()

if __name__ in "__main__":
    list = [chr(i) + '_pkg' for i in range(ord('a'), ord('z') + 1)]
    max_proc = 5
    pm = procManager(list, max_proc)
    cmd = 'sleep 5'
    pm.procExec(cmd)
