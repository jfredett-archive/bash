#!/bin/bash 

function safe() {
    ############################################################################
    # parses the .gitignore in the current directory,                          # 
    # looks for the "##~" line, and grabs any filepaths                        #
    # listed after it.                                                         #   
    # TODO: make this maybe not have to call so many externals? Why won't      #
    #       bash arrays work nicely? :(                                        #
    ############################################################################
    function parse_gitignore() { #{{{
        manifest=$1 # output parameter
        path=$2

        shift; shift; 

        if [[ $path ]] ; then
            use_path="$path/.gitignore"
        else 
            use_path="$PWD/.gitignore"
        fi

        files=`cat $use_path`
        for file in $files ; do
            if [[ "$file" = "##~" ]] ; then
                shouldcount="true"
            fi
            if [[ -n $file && $shouldcount ]] ; then 
                count=$[$count + 1]
            fi 
        done

        manifest=`tail -n $count .gitignore`
    } #}}}

    function check_status() {
        return 1
    }

    ############################################################################
    # updates the contents of the $path/.safe directory with copies of the     #
    # files listed in the manifest.                                            #
    ############################################################################
    function update_safe_contents() { #{{{
        path=$1

        declare -a manifest
        parse_gitignore "$manifest" "$path"

        shift 

        #####

        echo $path
        if [[ ! -d "$path/.safe" ]] ; then 

            mkdir "$path/.safe"
        fi

        for file in $manifest ; do 
            cp $file "$path/.safe"
        done

    } #}}}

    ###########################################################################
    # This will create a `safe.tgz.enc` file in the parent directory of the   #
    # .locked directory.                                                      #
    ###########################################################################
    function execute_lock() { #{{{
        safe_path="$1"
        shift;
        update_safe_contents "$safe_path"
        # Run status update -- that should take care of the conditional updating
        # Lock the box. use the argument if provided
        tar -cz "$safe_path/.safe" | openssl enc -aes-256-cbc > "$safe_path/safe.tgz.enc"
    } #}}}
    ###########################################################################
    # This will unlock the `safe.tgz.enc` file, overwriting the contents of   #
    # the .locked directory.                                                  # 
    # TODO: Make this move all the files back to their original locations as  #  
    # determined by the manifest file.                                        #
    ###########################################################################
    function execute_unlock() { #{{{
        locked_safe_path="$1"
        echo $locked_safe_path
        shift;
        # Check to see if the .lockbox is present, unless a specific argument is supplied
        if [[ -e "$locked_safe_path/safe.tgz.enc" ]] ; then 
            # unlock the box
            `openssl enc -d -aes-256-cbc -in "$locked_safe_path/safe.tgz.enc" | tar -zxv "$locked_safe_path/.safe" > /dev/null`
            rm "$locked_safe_path/safe.tgz.enc"
        else
            #exit with failure
            echo "Encrypted safebox doesn't exist"
            return 1
        fi
    } #}}}

    ################################################################################
    # lockbox_manager parses input commands and calls the correct method based on  #
    # the input. (hey look, objects in my bash!)                                   #
    #                                                                              #
    # TODO: extract this into a separate script, how do I hide the utility fu--    #
    #       !!! MAKE THEM NESTED FUNCTIONS!                                        #
    #       We can change the name of lockbox to lockbox manager, wrap this whole  #
    #       script in a function (called lockbox), then you source this somewhere, #
    #       and use lockbox. All the functions I define are local, and can't be    #
    #       called from the outside.                                               #
    ################################################################################
    function safe_manager() { #{{{
        path=$1
        option=$2 
        
        shift; shift;

        ############################################################################


        case "$option" in
            "lock")
                execute_lock "$path"
                ;;
            "unlock")
                execute_unlock "$path"
                ;;
            "status")
                check_status
                ;;
            "update") 
                update_safe_contents "$path"
                ;;
            *) 
                #TODO: USAGE STUFF HERE
                echo "FAIL!"
                ;;
        esac
    } #}}}

    safe_manager $1 $2
}



