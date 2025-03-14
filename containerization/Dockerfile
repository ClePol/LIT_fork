FROM deepmi/fastsurfer:cuda-v2.4.2

#RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN mkdir -p /inpainting/weights && pip3 install monai==1.4.0

RUN apt update && apt install -y curl

RUN curl https://zenodo.org/records/14510136/files/model_axial.pt -o /inpainting/weights/model_axial.pt && \
    curl https://zenodo.org/records/14510136/files/model_coronal.pt -o /inpainting/weights/model_coronal.pt && \
    curl https://zenodo.org/records/14510136/files/model_sagittal.pt -o /inpainting/weights/model_sagittal.pt

COPY lit run_lit.sh pyproject.toml git.hash /inpainting/

ENV INPAINTING_DIR=/inpainting
RUN mv /fastsurfer/run_fastsurfer.sh /fastsurfer/run_fastsurfer_segmentation.sh && \
    echo "cd /inpainting/ && ./run_lit.sh \"\$@"\" >> /fastsurfer/run_fastsurfer.sh && \
    chmod +x /fastsurfer/run_fastsurfer.sh

ENTRYPOINT ["/bin/bash", "/inpainting/run_lit.sh"]

WORKDIR /inpainting
