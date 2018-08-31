# devops

This package has set-out to be a mini devops all-in-one.  

It can:
Clean a directory of CSV files, create a MySQL database and load each file into a table.
Display a multiscreen display of system metrics, monitoring, and stats.  (Installs and uses Tmux).


#There are currently 3 bash scripts included:
#Deploy.sh
      Will prompt and configure your deployments to github. 
      All thats needed to deploy is to type $sh deploy.sh
      It will ask the username, password and branch name (once a day).

#Devops.sh 
       A suite of tools that speeds up common IT/Devops/SysAdmin tasks
     ($devops.sh -h)
      Options:  
            Install     -  install pip, python, puppet, mysql, tmux, htop & system/network monitoring tools.
            Test        -  Test the master server.
            Performance -  Performance check the main devops components.
            System Info -  Prints related info about the server.
            Disk info   -  Disk space monitor and freespace calculator.
            Memory Info -  Memory usage monitor and process utilization tool.
            CPU Stats   -  Display CPU availability and usage.
            Network     -  Get statistics about connections and usage.
            Monitor All -  Opens a Tmux session with 6 panes of metrics and reporting. CtrlB-d to hide.
            Devops Check - Uses parallel SSH commands to check the status of all nodes in hosts.txt

#CSVconverter.sh
      Point toward a directory of raw CSV files, using -i (input) or -o (output).
      it will endeavor to unify the delimiters, parse the field names, and trim long column names
      to prepare for database loading.
      Will create a mysql database "DataLook"
      Run CSVconverter.sh -c once to enter mysql credentials config.
      








