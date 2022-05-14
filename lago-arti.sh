#!/bin/bash
# /************************************************************************/
# /* Package:  ARTI                                                       */
# /* Module:   arti.sh									                              */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernan.asoreyh@iteda.cnea.gov.ar                           */
# /************************************************************************/
# /* Comments: Configure environment variables for a fresh ARTI install   */
# /************************************************************************/
# /*
# LICENSE BSD-3-Clause
# Copyright (c) 2015
# The LAGO Collaboration
# https://lagoproject.net
# All rights reserved.
#   -*- coding: utf8 -*-
VERSION="v1r9"
export ARTI=${PWD}
date=$(date -u)
echo "
#
## Changes added by the ARTI suite $VERSION on $date
#
export ARTI=\"${ARTI}\"
export PATH=\"\${ARTI}/sims/:\${ARTI}/analysis:\$PATH\"
" >> ${HOME}/.bashrc