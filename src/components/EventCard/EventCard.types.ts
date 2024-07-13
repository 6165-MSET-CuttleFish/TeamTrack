typescript
export interface EventCardProps {
  title: string;
  location: string;
  date: Date;
  description: string;
  imageUrl: string;
  onPress?: () => void;
}