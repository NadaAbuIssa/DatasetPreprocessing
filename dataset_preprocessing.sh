
#!/bin/bash
#main_function
main(){
    menu
    #a loop used to display the menu by calling the menu function while the do_exist not eqaul 1
    #(do_exist = 1 only if the user varify to exist by choosing exist from the menu)
    while [ "$do_exit" -ne "1" ];
    do
        menu
    done
}
#menu_function
menu() {
    #print the menu
    echo -e "\nr) read a dataset from a file"
    echo "p) print the names of the features"
    echo "l) encode a feature using label encoding"
    echo "o) encode a feature using one-hot encoding"
    echo "m) apply MinMax scalling"
    echo "s) save the processed dataset"
    echo -e "e) exit\n"
    read choise #read user choise
    ## if statement to make sure that the first selected choise only 'r' or 'e'
    # allow = 1 only if the file read successfully
    if [[ "$allow" -eq "1" ]] || [[ "$choise" == "r" ]] || [[ "$choise" == "e" ]];
    then
        do_logic
    else
        echo "You must first read a datasetfrom a file"
    fi
    
}
#Menu procedures function
do_logic(){
    case $choise in
        #if the user select 'r'
        r)
            allow=0
            echo "Please input the name of the dataset file"
            read file
            #if statment check that the file is Exist
            if test -f "$file"; then
                first_row_length=$(head -1 $file | tr ';' ' ' | wc -w ) #number of featurs in the first line
                #wile loop read line by line and check if the line have the same number of features as the first line(formatting)
                while read -r line; do
                    row_length=$(echo $line | tr ';' ' ' | wc -w ) #number of features in the line
                    if [ "$row_length" -ne "$first_row_length" ]; then  #if the format is wrong
                        echo "The format of the data in the dataset file is wrong"
                        allow=0
                        menu
                        break
                    fi
                done < "$file"
                #if the format is true
                echo -e "File read successfully\n"
                allow=1
                #make a copy from the file to a hidden file(the aim is to make the chages in a temp file until the user save them)
                cp $file .tmp_file
                menu
            else #if the file does not exist
                echo "file does not exist"
                allow=0
                menu
            fi
        ;;
        #if the user select 'p'
        p)
            #printing the features name
            echo -e "The features are : $(head -1 .tmp_file | tr ';' ' ')\n"
            menu
        ;;
        #if the user select 'l'
        l)
            #label encoding
            echo "Please input the name of the categorical feature for label encoding"
            read Feature_name
            feature_length=$(head -1 .tmp_file | tr ';' ' ' | wc -w)
            l_flag=0 #flag used to varify that the feature name is exist
            #for loop from 1 to the last feature in the first line
            for (( i=1; i<=${feature_length}; i++ ));
            do
                f=$(head -1 .tmp_file | cut -d ';' -f${i}) #f will represent one feature each time it loops
                #checking if the intered feature = f(if true the featuer exist)
                if [ "$f" == "$Feature_name" ]
                then
                    l_flag=1 #flag used to varify that the feature name is exist
                    #store feature uniq values in an array
                    f_array=$(cat .tmp_file | cut -d';' -f${i} | sort -ru |  grep -v -e "$Feature_name")
                    x=0
                    for j in ${f_array};  #loop in the feature
                    do
                        #print distinct values of the categorical feature and the code of each value
                        echo "$j = $x"
                        #replace each value with its new value and store them in the temp file
                        sed -i "s/\b${j}\b/${x}/g" .tmp_file >>! .tmp_file
                        (( x ++ ))
                    done
                    menu
                fi
            done
            #if the feature name is wrong
            if [ "$l_flag" -ne "1" ]; then
                
                echo "The name of categorical feature is wrong"
                menu
            fi
        ;;
        #if the user select 'o'
        o)
            #one-hot encoding
            echo "Please input the name of the categorical feature for one-hot encoding"
            read Feature_name
            feature_length=$(head -1 .tmp_file | tr ';' ' ' | wc -w)
            o_flag=0  #flag used to varify that the feature name is exist
            #for loop from 1 to the last feature in the first line
            for (( i=1; i<=${feature_length}; i++ ));
            do
                f=$(head -1 .tmp_file | cut -d ';' -f${i}) #f will represent one feature each time it loops
                #checking if the intered feature = f(if true the featuer exist)
                if [ "$f" == "$Feature_name" ]
                then
                    o_flag=1  #flag used to varify that the feature name is exist
                    #store feature uniq values in an array
                    f_array=$(cat .tmp_file | cut -d';' -f${i} | sort -ru | grep -v -e "$Feature_name")
                    #replace the old feature name with its uniq values
                    sed  -i "1s/$Feature_name/$(echo $f_array | tr  ' ' ';')/g"  .tmp_file
                    y=0
                    length=$(cat .tmp_file | wc -l)
                    #loops in each line
                    for (( z=1; z<=${length}; z++ ));
                    do
                        #old value of the feature in that line
                        old_value=$(head -$(echo $(( z + 1 )))  .tmp_file | tail -1 | cut -d ';' -f${i})
                        new_value=""
                        #loop in the new features
                        for array_value in ${f_array};
                        do
                            #store '0' or '1' in the new value
                            if [ "$old_value" == "$array_value" ];
                            then
                                data="1"
                            else
                                data="0"
                            fi
                            
                            if [ "$new_value" == "" ];then
                                new_value="$data"
                            else
                                new_value="$new_value;$data"
                            fi
                        done
                        #replace the old value with '0' or '1'
                        sed -i  "$(echo $(( z + 1 )))s/\b$old_value\b/$(echo $new_value)/g" .tmp_file
                    done
                    #print the distinct values of the categorical feature
                    echo ${f_array}
                    echo -e "$Feature_name\n" >> encoded.txt
                    menu
                fi
            done
            #if the feature name is wrong
            if [ "$o_flag" -ne "1" ]; then
                
                echo "The name of categorical feature is wrong"
                menu
            fi
        ;;
        #if the user select 'm'
        m)
            #MinMax scalling
            echo "Please input the name of the feature to be scaled"
            read Feature_name
            feature_length=$(head -1 .tmp_file | tr ';' ' ' | wc -w)
            m_flag=0 #flag used to varify that the feature name is exist
            for (( a=1; a<=${feature_length}; a++ ));
            do
                f=$(head -1 .tmp_file | cut -d ';' -f${a})
                #checking if the intered feature = f   (if true the featuer exist)
                
                if [ "$f" == "$Feature_name" ];
                then
                    #store feature values
                    values_array=$(cat .tmp_file | cut -d';' -f${a} | grep -v -e "$Feature_name")
                    m_flag=1 #flag used to varify that the feature name is exist
                    #loop in the feature values
                    for m in ${values_array};
                    do
                        #varify that the entered feature is not a categorical feature by checking its values
                        [ "${m}" -eq "${m}" ] 2>/dev/null
                        if [[ $? -eq "0" ]];
                        then
                            #after varify that values are numeric
                            #minimum value
                            minimum=$(cat .tmp_file | cut -d ';' -f${a} | sort | grep -v -e "$Feature_name" | head -1)
                            #maximum value
                            maximum=$(cat .tmp_file | cut -d ';' -f${a} | sort | grep -v -e "$Feature_name" | tail -1)
                            echo  "Minimum value = $minimum    Maximum value = $maximum"
                            #p represint line number to start from the second line
                            p=2
                            for s in ${values_array};
                            do
                                #calculating the scaled value
                                numerator=$((${s}-${minimum}))
                                denominator=$((${maximum}-${minimum}))
                                scaled_val=$(printf "%.1f" "$(echo "scale=2;${numerator}/${denominator}" | bc)")
                                #replace old value with the scaled one
                                sed -i "${p}s/\b${s}\b/${scaled_val}/g" .tmp_file >>! .tmp_file
                                (( p ++ ))
                            done
                            menu
                            break
                            #when the feature is categoric
                        else
                            echo "this feature is categorical feature and must be encoded first"
                            menu
                            break
                        fi
                    done
                fi
            done
            #if the feature name is wrong
            if [ "$m_flag" -ne "1" ]; then
                
                echo "The name of feature is wrong"
                menu
            fi
        ;;
        #if the user select 's'
        s)
            #save the processed dataset
            echo "Please input the name of the file to save the processed dataset"
            read processed_file
            #copy the processed dataset from the temp file to the entered one
            cp .tmp_file $processed_file
            save=1
            menu
        ;;
        #if the user select 'e'
        e)
            #exist
            varify=""
            #if the processed dataset is not saved
            if [ "$save" -ne "1" ];
            then
                echo "The processed dataset is not saved. Are you sure you want to exist"
                read varify
                if [ "$varify" == "yes" ];
                then
                    do_exit=1
                else
                    menu
                fi
            else
                #when the processed dataset have been saved
                echo "Are you sure you want to exist"
                read varify
                if [ "$varify" == "yes" ];
                then
                    do_exit=1
                else
                    menu
                fi
            fi
        ;;
        #if the user select any vaue that is not in the menu
        *)
            echo "Please choose from the menu"
            menu
        ;;
    esac
}
#variable initialing
save=0
allow=0
do_exit=0
#calling main functin
main