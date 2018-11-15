#! /usr/bin/env python3

import argparse
import subprocess
import sys
import re
import os
import shutil

description="Download ATL09 data from NSIDC." +\
    "  To use this, you must generate a token, using the setup_token script, which will be saved in a file called NSIDC_token.txt"+\
    "The script will search for NSIDC_token.txt in the current directory (first) and in the directory where the script is located (second)."
    

parser=argparse.ArgumentParser(description=description)
parser.add_argument('-f', dest='full_file', default=False, action='store_true')
parser.add_argument('-o', dest='output_directory', type=str)
parser.add_argument('-d', dest='dry_run', default=False, action='store_true')
parser.add_argument('-t', dest='time_str', required=True, default=None, help="Time range for query.  Format is YYYY-MM-DDTHH:MM:SS,YYYY-MM-DDTHH:MM:SS")
args=parser.parse_args()

# look for a NSIDC_identity.txt file in the current directory
try:
    fh=open('NSIDC_token.txt','r')
except(FileNotFoundError):
    # also look in the script's directory
    fh=open(sys.path[0]+'/NSIDC_token.txt','r')

token=None
token_re=re.compile('<id>(.*)</id>')
for line in fh:
    m=token_re.search(line)
    if m is not None:
        token=m.group(1)
if token is None:
    raise RuntimeError('missing token string')

token_str='&token=%s' % token
 
if 'out_dir' in args:
    os.chdir(args.output_directory)

if args.full_file:
    subset_str="&agent=NO"
else:
    subset_str=""

time_str="&time=%s" % args.time_str
 
# build the query to submit via curl
cmd_base='curl -O -J --dump-header response-header.txt "https://n5eil02u.ecs.nsidc.org/egi/request?short_name=ATL09&version=200&page_size=1000' 
cmd=cmd_base+'%s%s%s"' % (token_str, subset_str, time_str)

print(cmd)

if args.dry_run:
    # if this is a dry run, exit after reporting the string
    exit()

# run the curl string
p=subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
text=p.stdout.read()
retcode=p.wait()

# check the response header to get the filename with the output
zip_re=re.compile('filename="(.*.zip)"')
with open('response-header.txt') as ff:
    for line in ff:
        m=zip_re.search(line)
        if m is not None:
            zip_file=m.group(1)
zip_str=subprocess.check_output(['unzip',zip_file])

# the output from unzipping the zip file is a set of directories containing the
# h5 data files. pull the indivicual h5 files into the current directory
cleanup_list=list()
for h5_file in re.compile('(\S+\.h5)').findall(zip_str.decode('utf-8')):
    shutil.move(h5_file,'.')
    thedir=os.path.dirname(h5_file)
    if thedir not in cleanup_list:
        cleanup_list.append( thedir)
        
# delete the directories that contained the hdf5 files
for entry in cleanup_list:
    os.rmdir(entry)
os.remove(zip_file)
    
    


