#!/bin/bash

function outputDate() {
	current_date_time="`date "+%m-%d-%Y %H:%M:%S"`";
	echo "[$current_date_time] [info]  $1"
}