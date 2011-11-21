#include <stdio.h>
#include <strings.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

void sendit(char *msg)
{
	struct sockaddr_in addr;
	int sock = socket(AF_INET,SOCK_DGRAM,0);

	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = inet_addr("127.0.0.1");
	addr.sin_port = htons(3500);

	sendto(sock, msg, strlen(msg), 0, (const struct sockaddr *)&addr, sizeof(struct sockaddr));
}

int main(int argc, char**argv)
{
	int sockfd;
	struct sockaddr_in server_addr, client_addr;
	char mesg[4096];

	if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		fprintf(stderr, "socket failed\n");
		exit(EXIT_FAILURE);
	}

	memset(&server_addr, 0, sizeof(server_addr));
	server_addr.sin_family = AF_INET;
	server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	server_addr.sin_port = htons(9999);

	if (bind(sockfd,(struct sockaddr *)&server_addr,sizeof(server_addr)) < 0) {
		fprintf(stderr, "bind failed\n");
		exit(EXIT_FAILURE);
	}

	for (;;) {
		int n;
		socklen_t len = sizeof(client_addr);

		if ((n = recvfrom(sockfd, mesg, 1000, 0, (struct sockaddr *)&client_addr, &len)) > 0) {
			mesg[n] = 0;
			sendit(mesg);
		}
	}
}
