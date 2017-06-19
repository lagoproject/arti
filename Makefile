#   Makefile   -- 
#   Copyright (C) 2012-TODAY The LAGO Project, http://lagoproject.org, lago-pi@lagoproject.org
#   Original authors: Hernán Asorey
#   e-mail: asoreyh@cab.cnea.gov.ar  (asoreyh@gmail.com)
#   Laboratorio de Detección de Partículas y Radiación (LabDPR)
#   Centro Atómico Bariloche - San Carlos de Bariloche, Argentina 
#
# LICENSE BSD-3-Clause
# Copyright (c) 2012, The LAGO Project
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 

#   -*- coding: utf8 -*-
#   try to preserve encoding  

CODE_DIR = analysis
TESTS = check-lago 

all: $(TESTS)
	$(MAKE) -C $(CODE_DIR)

.PHONY: clean

clean:
	$(MAKE) -C $(CODE_DIR) clean

check-lago:
ifndef LAGO_ARTI
	$(info LAGO_ARTI is not set.)
	$(info I will define it to $PWD, and modify the .bashrc)
	$(shell $(PWD)/lago-arti.sh)
	$(info Done. Now open a new terminal or execute source $(HOME)/.bashrc)
endif
