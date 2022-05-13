#!/bin/bash
# /************************************************************************/
# /* Package:  ARTI                                                       */
# /* Module:   lago_arti.sh									                              */
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
export LAGO_ARTI=${PWD}
date=$(date -u)
echo "
#
## Changes added by the LAGO ARTI suite $VERSION on $date
#
export LAGO_ARTI=\"${LAGO_ARTI}\"
export PATH=\"\${LAGO_ARTI}/sims/:\${LAGO_ARTI}/analysis:\$PATH\"
" >> ${HOME}/.bashrc