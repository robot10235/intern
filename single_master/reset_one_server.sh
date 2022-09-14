#!/bin/bash
echo "Now changing to one master..."
mysql -uroot -p123456 -e"set global read_only=0; stop slave; reset slave all;"
echo "sucess!"