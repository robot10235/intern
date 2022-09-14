#!/bin/bash
echo "Now changing to one master..."
mysql -uroot -p123456 -e"stop slave; reset slave all;"
echo "sucess!"