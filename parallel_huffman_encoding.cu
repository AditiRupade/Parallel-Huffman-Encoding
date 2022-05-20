#include<stdio.h>
#include<cuda.h>
#include<time.h>
#include <cstring>
#include <ctime>
#include <stdlib.h>
#include <sys/stat.h>

__global__ void calc_freq(int *f , char *data)
{
	int id=blockIdx.x * blockDim.x + threadIdx.x;
	int x=0;
	if(data[id] >= 'a' && data[id] <= 'z')
	{
		x = data[id] - 'a';
		f[x]++;
	}	
}

__global__ void compress(char *h_r, char *a, char *en,char *h_lt)
{
	int id=blockIdx.x * blockDim.x + threadIdx.x;
	if(h_lt[id] == a[id])
	{
		for(int j=0;j<5;j++)
		{
			h_r += en[id+j];
		}
	}
}

int main()
{
	int *freq;
	int *h_freq;
	char *letter;
	char *h_letter;
	
	freq = (int*)malloc(26*sizeof(int));
	cudaMalloc((void**)&h_freq, 26*sizeof(int));
	
	for(int i=0;i<26;i++)
	{
		freq[i] = 0;
	}
	
	FILE *fptr = fopen("input.txt" , "r");
	
	struct stat st; 
	int size;
     
    	if(stat("input.txt",&st)==0)
        	size = st.st_size;
    	else
        	size = -1;
        
        letter = (char*)malloc(size*sizeof(char));
	cudaMalloc((void**)&h_letter, size*sizeof(char));
	int k=0;
	while(k<size)
	{
		letter[k] = fgetc(fptr);
		k++;
        	//printf("%c", *letter);
	}
	
	for(int i=0;i<size;i++)
		printf("%c",letter[i]);

	int threadsPerBlock;
	if (size<=1024) 
		threadsPerBlock=size;
	else 
		threadsPerBlock=1024;
		
    	int blocksPerGrid =(size + threadsPerBlock - 1) / threadsPerBlock;
	printf("\nblocksPerGrid=%d\n",blocksPerGrid);
	
	cudaMemcpy(h_freq,freq,26*sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy(h_letter,letter,size*sizeof(char),cudaMemcpyHostToDevice);
	
	calc_freq<<<threadsPerBlock,blocksPerGrid>>>(h_freq,h_letter);
	
	cudaMemcpy(freq,h_freq,26*sizeof(int),cudaMemcpyDeviceToHost);
	
	for(int i=0 ; i<26 ; i++)
	{
		printf("%d\n",freq[i]);
	}
	
	char arr[26];
	
	char c;
	int i;
	
	for( i=0, c = 'A'; i<26, c <= 'Z'; i++, c++)
	{
		arr[i] = c;
		printf("%c",arr[i]);
	}
	
	for(i=0;i<26;i++)
	{
		for(int j=i;j<26;j++)
		{
			int temp;
			char ctemp;
			
			if(freq[i] < freq[j])
			{
				temp = freq[i];
				freq[i] = freq[j];
				freq[j] = temp;
				
				ctemp = arr[i];
				arr[i] = arr[j];
				arr[j] = ctemp;
			}
		}
	}
	
	char encode[26][5] = {{'0'},{'0','0'},{'0','1'},{'0','0','0'},{'0','0','1'},{'0','1','0'},{'0','1','1'},{'0','0','0','0'},{'0','0','0','1'},{'0','0','1','0'},{'0','0','1','1'},{'0','1','0','0'},{'0','1','0','1'},{'0','1','1','0'},{'0','1','1','1'},{'0','0','0','0','0'},{'0','0','0','0','1'},{'0','0','0','1','0'},{'0','0','0','1','1'},{'0','0','1','0','0'},{'0','0','1','0','1'},{'0','0','1','1','0'},{'0','0','1','1','1'},{'0','1','0','0','0'},{'0','1','0','0','1'},{'0','1','0','1','0'}};
	
	for(int i=0 ; i<26 ; i++)
	{
		printf("%c %d ",arr[i],freq[i]);
		for(int j=0;j<5;j++)
		{
			printf("%c",encode[i][j]);
		}
		printf("\n");
	}
	
	fptr = fopen("output.txt","w");
	//FILE *h_fptr;
	char *h_arr;
	cudaMalloc((void**)&h_arr, 26*sizeof(char));
	cudaMemcpy(h_arr,arr,26*sizeof(char),cudaMemcpyHostToDevice);
	char *h_en;
	cudaMalloc((void**)&h_en, 26*5*sizeof(char));
	cudaMemcpy(h_en,encode,26*5*sizeof(char),cudaMemcpyHostToDevice);
	//cudaMemcpy(h_fptr,fptr,26*5*sizeof(char),cudaMemcpyHostToDevice);
	char *h_res;
	cudaMalloc((void**)&h_res, 26*5*sizeof(char));
	compress<<<threadsPerBlock,blocksPerGrid>>>(h_res,h_arr,h_en,h_letter);
	char *res;
	cudaMemcpy(res,h_res,26*5*sizeof(char),cudaMemcpyDeviceToHost);
	for(int i=0 ; i<size*5;i++)
	{
		//printf("%c",res[i]);
		fprintf (fptr,"%c",res[i]);
	}
  	fclose(fptr);
	return 0;
}
