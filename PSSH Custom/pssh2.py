import configparser
import paramiko
import argparse


#   usage:
#   sh pssh.py -h hostfile.txt -l ec2-user -x "-i ATTproduction.pem" -A 'uname'
#   copy of the keys/pssh file



config = configparser.ConfigParser()

def mainconnect(cmd):
    hosts = None
    try:
        with open(filename) as f:
            hosts = f.read().splitlines()
    except IOError as e:
        print("Can't open host file:" + str(e))
        return
    f.close()
    print("Executing on servers:\n")
    for host in hosts:
        if host.startswith('#'):
            print ("host: ", host)
            print()
        else:
            print(host)
            try:
                if not args.keys:
                    client_key = paramiko.RSAKey.from_private_key_file("ATTproduction.pem")
                else:
                    client_key = paramiko.RSAKey.from_private_key_file(args.keys)
                c = paramiko.SSHClient()
                c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                c.connect(hostname=host,username="ec2-user",pkey=client_key,allow_agent=False,look_for_keys=False )
                print("Executing {}".format( cmd ))
                stdin , stdout, stderr = c.exec_command(cmd)
                print(stdout.read())
                c.close()
                print("\n\n")
            except Exception as e:
                print("Operation error: %s" % e)


def command(client, cmd):
    print("______________________________________")
    output = client.run_command(cmd)
    for host in output:
        for line in output[host]['stdout']:
            print("Host: %s - Output: %s" % (host, line))


def readConf(option): l
    config.read("gfa-pssh.conf")
    value = config['GENERAL'][option]
    return(value)


parser = argparse.ArgumentParser()
parser.add_argument(dest='input', help="Enter command to execute")
parser.add_argument("--file", "-f", type=str, required=True)
parser.add_argument("--keys", "-i", type=str)
args = parser.parse_args()
filename = args.file

if args.input == None:
    parser.print_help()
else:
    print("************************************")
    mainconnect(args.input)